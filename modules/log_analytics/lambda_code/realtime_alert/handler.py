"""
실시간 보안 알람 Lambda 핸들러
CloudTrail 보안 이벤트 감지 → 즉시 Slack 알림
ISMS-P 기준 보안 이벤트 모니터링
"""
import boto3
import json
import os
import urllib.request
from datetime import datetime

# 환경 변수
SLACK_SECRET_ARN = os.environ.get('SLACK_SECRET_ARN')
SLACK_CHANNEL = os.environ.get('SLACK_CHANNEL', '#kyeol-security-alerts')

# AWS 클라이언트
secrets = boto3.client('secretsmanager')

# ISMS-P 이벤트 심각도 분류
SEVERITY_MAP = {
    # 🔴 높음 (즉시 대응 필요)
    'ConsoleLogin': ('🔴', '높음', '콘솔 로그인'),
    'CreateUser': ('🔴', '높음', '사용자 생성'),
    'DeleteUser': ('🔴', '높음', '사용자 삭제'),
    'CreateAccessKey': ('🔴', '높음', 'Access Key 생성'),
    'DeleteAccessKey': ('🟠', '중간', 'Access Key 삭제'),
    'AttachUserPolicy': ('🔴', '높음', '사용자 정책 연결'),
    'DetachUserPolicy': ('🟠', '중간', '사용자 정책 분리'),
    'AttachRolePolicy': ('🔴', '높음', '역할 정책 연결'),
    'CreateRole': ('🔴', '높음', 'IAM 역할 생성'),
    'DeleteRole': ('🟠', '중간', 'IAM 역할 삭제'),
    # 🟠 중간 (모니터링 필요)
    'AuthorizeSecurityGroupIngress': ('🟠', '중간', '보안그룹 인바운드 규칙 추가'),
    'AuthorizeSecurityGroupEgress': ('🟠', '중간', '보안그룹 아웃바운드 규칙 추가'),
    'CreateSecurityGroup': ('🟠', '중간', '보안그룹 생성'),
    'DeleteSecurityGroup': ('🟠', '중간', '보안그룹 삭제'),
    # 🟡 낮음 (정보)
    'PutBucketPolicy': ('🟡', '낮음', 'S3 버킷 정책 변경'),
    'DeleteBucketPolicy': ('🟠', '중간', 'S3 버킷 정책 삭제'),
    'PutBucketPublicAccessBlock': ('🟡', '낮음', 'S3 퍼블릭 액세스 설정'),
    'DisableKey': ('🔴', '높음', 'KMS 키 비활성화'),
    'ScheduleKeyDeletion': ('🔴', '높음', 'KMS 키 삭제 예약'),
    'CreateKey': ('🟡', '낮음', 'KMS 키 생성'),
}


def lambda_handler(event, context):
    """메인 핸들러"""
    print(f"Received security event: {json.dumps(event)}")
    
    try:
        # CloudTrail 이벤트 파싱
        detail = event.get('detail', {})
        event_name = detail.get('eventName', 'Unknown')
        event_time = detail.get('eventTime', datetime.utcnow().isoformat())
        event_source = detail.get('eventSource', 'Unknown')
        aws_region = detail.get('awsRegion', 'Unknown')
        
        # 사용자 정보
        user_identity = detail.get('userIdentity', {})
        user_name = user_identity.get('userName', 
                   user_identity.get('principalId', 'Unknown'))
        user_type = user_identity.get('type', 'Unknown')
        
        # 소스 IP
        source_ip = detail.get('sourceIPAddress', 'Unknown')
        
        # 오류 정보
        error_code = detail.get('errorCode')
        error_message = detail.get('errorMessage')
        
        # Slack 알림 전송
        send_security_alert(
            event_name=event_name,
            event_time=event_time,
            event_source=event_source,
            aws_region=aws_region,
            user_name=user_name,
            user_type=user_type,
            source_ip=source_ip,
            error_code=error_code,
            error_message=error_message,
            raw_event=detail
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Alert sent successfully'})
        }
        
    except Exception as e:
        print(f"Error processing security event: {str(e)}")
        raise


def get_slack_webhook():
    """Secrets Manager에서 Slack Webhook URL 가져오기"""
    response = secrets.get_secret_value(SecretId=SLACK_SECRET_ARN)
    return response['SecretString']


def send_security_alert(event_name, event_time, event_source, aws_region,
                        user_name, user_type, source_ip, 
                        error_code, error_message, raw_event):
    """Slack 보안 알림 전송"""
    
    webhook_url = get_slack_webhook()
    
    # 심각도 및 설명 가져오기
    severity_info = SEVERITY_MAP.get(event_name, ('🟡', '낮음', event_name))
    emoji, severity, description = severity_info
    
    # 실패 여부 확인
    is_failed = error_code is not None
    status_text = f"❌ 실패 ({error_code})" if is_failed else "✅ 성공"
    
    # 색상 결정
    color_map = {'높음': 'danger', '중간': 'warning', '낮음': 'good'}
    color = 'danger' if is_failed else color_map.get(severity, 'good')
    
    # 시간 포맷팅
    try:
        event_dt = datetime.fromisoformat(event_time.replace('Z', '+00:00'))
        formatted_time = event_dt.strftime('%Y-%m-%d %H:%M:%S UTC')
    except:
        formatted_time = event_time
    
    message = {
        "channel": SLACK_CHANNEL,
        "attachments": [
            {
                "color": color,
                "blocks": [
                    {
                        "type": "header",
                        "text": {
                            "type": "plain_text",
                            "text": f"{emoji} ISMS-P 보안 이벤트 감지",
                            "emoji": True
                        }
                    },
                    {
                        "type": "section",
                        "fields": [
                            {"type": "mrkdwn", "text": f"*이벤트*\n`{event_name}`"},
                            {"type": "mrkdwn", "text": f"*설명*\n{description}"},
                            {"type": "mrkdwn", "text": f"*심각도*\n{severity}"},
                            {"type": "mrkdwn", "text": f"*상태*\n{status_text}"},
                            {"type": "mrkdwn", "text": f"*사용자*\n{user_name}"},
                            {"type": "mrkdwn", "text": f"*유형*\n{user_type}"},
                            {"type": "mrkdwn", "text": f"*소스 IP*\n{source_ip}"},
                            {"type": "mrkdwn", "text": f"*리전*\n{aws_region}"}
                        ]
                    },
                    {
                        "type": "context",
                        "elements": [
                            {"type": "mrkdwn", "text": f"📅 {formatted_time} | 📡 {event_source}"}
                        ]
                    }
                ]
            }
        ]
    }
    
    # 오류 메시지 추가
    if error_message:
        message["attachments"][0]["blocks"].append({
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"*오류 상세*\n```{error_message[:500]}```"}
        })
    
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(message).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    
    urllib.request.urlopen(req)
    print(f"Security alert sent for event: {event_name}")
