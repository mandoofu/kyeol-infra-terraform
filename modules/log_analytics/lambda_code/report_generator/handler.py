"""
정기 리포트 생성 Lambda 핸들러
Athena 쿼리 → Bedrock AI 분석 → S3 저장 → Slack 알림
"""
import boto3
import json
import os
import urllib.request
from datetime import datetime, timedelta

# 환경 변수
AUDIT_BUCKET = os.environ.get('AUDIT_BUCKET')
REPORT_BUCKET = os.environ.get('REPORT_BUCKET')
ATHENA_WORKGROUP = os.environ.get('ATHENA_WORKGROUP')
ATHENA_DATABASE = os.environ.get('ATHENA_DATABASE')
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID')
BEDROCK_REGION = os.environ.get('BEDROCK_REGION', 'us-east-1')
SLACK_SECRET_ARN = os.environ.get('SLACK_SECRET_ARN')
SLACK_CHANNEL = os.environ.get('SLACK_CHANNEL', '#kyeol-security-alerts')
AWS_ACCOUNT_ID = os.environ.get('AWS_ACCOUNT_ID')

# AWS 클라이언트
athena = boto3.client('athena')
s3 = boto3.client('s3')
bedrock = boto3.client('bedrock-runtime', region_name=BEDROCK_REGION)
secrets = boto3.client('secretsmanager')


def lambda_handler(event, context):
    """메인 핸들러"""
    report_type = event.get('report_type', 'daily')
    
    print(f"Starting {report_type} report generation...")
    
    try:
        # 1. 기간 설정
        end_date = datetime.utcnow()
        if report_type == 'daily':
            start_date = end_date - timedelta(days=1)
        elif report_type == 'weekly':
            start_date = end_date - timedelta(days=7)
        elif report_type == 'monthly':
            start_date = end_date - timedelta(days=30)
        else:
            start_date = end_date - timedelta(days=1)
        
        # 2. Athena 쿼리 실행
        query_results = run_athena_query(start_date, end_date)
        
        # 3. Bedrock AI 분석
        ai_summary = analyze_with_bedrock(query_results, report_type, start_date, end_date)
        
        # 4. 리포트 생성 및 S3 저장
        report_url = save_report(ai_summary, report_type, start_date, end_date)
        
        # 5. Slack 알림
        send_slack_notification(ai_summary, report_type, report_url, start_date, end_date)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'{report_type} report generated successfully',
                'report_url': report_url
            })
        }
        
    except Exception as e:
        print(f"Error generating report: {str(e)}")
        # 오류 발생 시에도 Slack 알림
        send_error_notification(str(e), report_type)
        raise


def run_athena_query(start_date, end_date):
    """Athena 쿼리 실행"""
    query = f"""
    SELECT 
        eventname,
        eventsource,
        useridentity.username as username,
        sourceipaddress,
        COUNT(*) as event_count
    FROM cloudtrail_logs
    WHERE eventtime >= '{start_date.strftime("%Y-%m-%dT%H:%M:%SZ")}'
      AND eventtime < '{end_date.strftime("%Y-%m-%dT%H:%M:%SZ")}'
    GROUP BY eventname, eventsource, useridentity.username, sourceipaddress
    ORDER BY event_count DESC
    LIMIT 100
    """
    
    # 쿼리 실행
    response = athena.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': ATHENA_DATABASE},
        WorkGroup=ATHENA_WORKGROUP
    )
    
    query_execution_id = response['QueryExecutionId']
    
    # 쿼리 완료 대기
    while True:
        result = athena.get_query_execution(QueryExecutionId=query_execution_id)
        state = result['QueryExecution']['Status']['State']
        
        if state == 'SUCCEEDED':
            break
        elif state in ['FAILED', 'CANCELLED']:
            reason = result['QueryExecution']['Status'].get('StateChangeReason', 'Unknown')
            raise Exception(f"Athena query failed: {reason}")
        
        import time
        time.sleep(2)
    
    # 결과 가져오기
    results = athena.get_query_results(QueryExecutionId=query_execution_id)
    
    # 결과 파싱
    rows = results['ResultSet']['Rows']
    if len(rows) <= 1:
        return "쿼리 결과가 없습니다."
    
    # 헤더 제외한 데이터 포맷팅
    formatted_results = []
    for row in rows[1:]:  # 헤더 제외
        values = [col.get('VarCharValue', '') for col in row['Data']]
        formatted_results.append(f"이벤트: {values[0]}, 소스: {values[1]}, 사용자: {values[2]}, IP: {values[3]}, 횟수: {values[4]}")
    
    return "\n".join(formatted_results[:50])  # 상위 50개만


def analyze_with_bedrock(query_results, report_type, start_date, end_date):
    """Bedrock으로 AI 분석"""
    
    report_type_kr = {
        'daily': '일간',
        'weekly': '주간',
        'monthly': '월간'
    }.get(report_type, '일간')
    
    prompt = f"""당신은 AWS 보안 분석가입니다. ISMS-P 기준에 따라 CloudTrail 로그를 분석하고 {report_type_kr} 보안 리포트를 작성하세요.

## 분석 기간
- 시작: {start_date.strftime("%Y-%m-%d %H:%M")} UTC
- 종료: {end_date.strftime("%Y-%m-%d %H:%M")} UTC

## CloudTrail 로그 요약
{query_results}

## 리포트 형식 (한글로 작성)
1. **주요 이벤트 요약** (3-5줄)
2. **보안 이상 징후** (ISMS-P 관점)
   - 비정상적인 로그인 시도
   - 권한 변경 이벤트
   - 보안 그룹 수정
3. **통계**
   - 총 이벤트 수
   - 상위 이벤트 타입
   - 상위 사용자
4. **권장 조치사항** (있으면)

간결하고 핵심만 포함하세요."""

    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2000,
        "messages": [
            {"role": "user", "content": prompt}
        ]
    })
    
    response = bedrock.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        body=body,
        contentType='application/json',
        accept='application/json'
    )
    
    response_body = json.loads(response['body'].read())
    return response_body['content'][0]['text']


def save_report(ai_summary, report_type, start_date, end_date):
    """리포트를 S3에 저장"""
    
    report_date = end_date.strftime("%Y-%m-%d")
    report_key = f"reports/{report_type}/{report_date}.md"
    
    report_content = f"""# KYEOL {report_type.upper()} 보안 리포트

> **생성일**: {datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")} UTC  
> **분석 기간**: {start_date.strftime("%Y-%m-%d")} ~ {end_date.strftime("%Y-%m-%d")}  
> **AI 모델**: Claude Haiku (Bedrock)

---

{ai_summary}

---

*이 리포트는 ISMS-P 규정 준수를 위해 자동 생성되었습니다.*
"""
    
    s3.put_object(
        Bucket=REPORT_BUCKET,
        Key=report_key,
        Body=report_content.encode('utf-8'),
        ContentType='text/markdown; charset=utf-8'
    )
    
    # Pre-signed URL 생성 (7일 유효)
    url = s3.generate_presigned_url(
        'get_object',
        Params={'Bucket': REPORT_BUCKET, 'Key': report_key},
        ExpiresIn=604800
    )
    
    return url


def get_slack_webhook():
    """Secrets Manager에서 Slack Webhook URL 가져오기"""
    response = secrets.get_secret_value(SecretId=SLACK_SECRET_ARN)
    return response['SecretString']


def send_slack_notification(ai_summary, report_type, report_url, start_date, end_date):
    """Slack 알림 전송"""
    
    webhook_url = get_slack_webhook()
    
    report_type_kr = {
        'daily': '일간',
        'weekly': '주간',
        'monthly': '월간'
    }.get(report_type, '일간')
    
    # AI 요약에서 첫 200자만 추출
    summary_preview = ai_summary[:300] + "..." if len(ai_summary) > 300 else ai_summary
    
    message = {
        "channel": SLACK_CHANNEL,
        "blocks": [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": f"📊 KYEOL {report_type_kr} 보안 리포트", "emoji": True}
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*기간*\n{start_date.strftime('%Y-%m-%d')} ~ {end_date.strftime('%Y-%m-%d')}"},
                    {"type": "mrkdwn", "text": f"*생성 시간*\n{datetime.utcnow().strftime('%H:%M')} UTC"}
                ]
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*AI 요약*\n```{summary_preview}```"}
            },
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "📄 상세 리포트 보기"},
                        "url": report_url,
                        "style": "primary"
                    }
                ]
            }
        ]
    }
    
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(message).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    
    urllib.request.urlopen(req)


def send_error_notification(error_message, report_type):
    """오류 발생 시 Slack 알림"""
    try:
        webhook_url = get_slack_webhook()
        
        message = {
            "channel": SLACK_CHANNEL,
            "blocks": [
                {
                    "type": "header",
                    "text": {"type": "plain_text", "text": "⚠️ 리포트 생성 오류", "emoji": True}
                },
                {
                    "type": "section",
                    "text": {"type": "mrkdwn", "text": f"*{report_type}* 리포트 생성 중 오류가 발생했습니다.\n```{error_message}```"}
                }
            ]
        }
        
        req = urllib.request.Request(
            webhook_url,
            data=json.dumps(message).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        
        urllib.request.urlopen(req)
    except:
        pass  # 오류 알림 실패는 무시
