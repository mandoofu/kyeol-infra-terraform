# 🏗️ kyeol-infra-terraform

> **KYEOL Saleor 프로젝트의 AWS 인프라를 Terraform으로 관리하는 IaC 레포지토리**

---

## 📌 이 레포는 무엇을 하는가

AWS에 Saleor 애플리케이션을 운영하기 위한 **전체 인프라**를 코드로 정의하고 배포합니다.

**생성되는 리소스**:
- VPC, Subnets, NAT Gateway
- EKS Cluster + Node Groups
- RDS PostgreSQL
- ElastiCache (Valkey/Redis)
- ECR Repositories
- IAM Roles (IRSA)
- Security Groups

---

## 👤 언제 / 누가 / 왜 사용하는가

| 상황 | 사용 여부 |
|------|:--------:|
| 새 환경(DEV/STAGE/PROD) 생성 | ✅ 사용 |
| 인프라 스펙 변경 (노드 수, 인스턴스 타입) | ✅ 사용 |
| Storefront/Dashboard 배포 | ❌ 미사용 (kyeol-app-gitops 사용) |
| Helm Addon 설치 | ❌ 미사용 (kyeol-platform-gitops 사용) |

---

## 🏛️ 전체 아키텍처에서의 위치

```
[이 레포] kyeol-infra-terraform
    ↓ (AWS 리소스 생성)
[AWS] VPC, EKS, RDS, Valkey, ECR
    ↓ (kubeconfig 설정)
[kyeol-platform-gitops] Helm Addons 설치
    ↓ (ALB Controller, ExternalDNS Ready)
[kyeol-app-gitops] 앱 배포
    ↓
[kyeol-storefront / kyeol-saleor-dashboard] 이미지 빌드
```

---

## 📁 주요 디렉터리/파일 설명

```
kyeol-infra-terraform/
├── envs/                    # 환경별 Terraform 루트
│   ├── bootstrap/           # S3 Backend, DynamoDB Lock (최초 1회)
│   ├── mgmt/                # MGMT 환경 (옵션)
│   ├── dev/                 # DEV 환경
│   ├── stage/               # STAGE 환경
│   └── prod/                # PROD 환경
├── modules/                 # 재사용 가능한 Terraform 모듈
│   ├── vpc/                 # VPC, Subnets, NAT
│   ├── eks/                 # EKS Cluster, Node Groups, IRSA
│   ├── rds_postgres/        # RDS PostgreSQL
│   ├── valkey/              # ElastiCache Valkey
│   └── ecr/                 # ECR Repositories
├── global/                  # 글로벌 공용 리소스
└── trust-policy.json        # GitHub OIDC Trust Policy
```

### envs/ 디렉터리 파일 구성

| 파일 | 역할 |
|------|------|
| `main.tf` | 모듈 호출 및 리소스 정의 |
| `variables.tf` | 변수 선언 |
| `terraform.tfvars.example` | 변수 예시 (복사하여 사용) |
| `terraform.tfvars` | ⚠️ **실제 값** (Git 커밋 금지!) |
| `outputs.tf` | 출력값 정의 |
| `backend.tf` | S3 백엔드 설정 |

---

## ⚠️ 이 레포를 직접 만질 때 주의사항

### 🚫 절대 하지 말아야 할 것

1. **`terraform.tfvars` 파일을 Git에 커밋하지 마세요**
   - 민감 정보 포함 (DB 비밀번호 등)
   - `.gitignore`에 등록되어 있음

2. **PROD 환경에서 `terraform destroy` 금지**
   - `rds_deletion_protection = true` 설정 확인

3. **IRSA 권한 수동 수정 금지**
   - 반드시 `modules/eks/iam_irsa.tf` 코드로 관리

### ✅ 반드시 해야 할 것

1. **`terraform plan` 먼저 실행**하여 변경 사항 확인

2. **`terraform.tfvars.example`을 복사**하여 `terraform.tfvars` 생성

---

## 🔗 다른 레포와의 관계

| 레포지토리 | 관계 |
|-----------|------|
| kyeol-platform-gitops | **이 레포 실행 후** Helm Addons 설치에 사용 |
| kyeol-app-gitops | EKS 클러스터 생성 후 앱 배포에 사용 |
| docs | 런북 참조 (실행 순서, 트러블슈팅) |

---

## 🚀 빠른 시작

```powershell
# 1. 환경 디렉터리 이동
cd envs/stage

# 2. tfvars 생성
Copy-Item terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집

# 3. 초기화
terraform init

# 4. 계획 확인
terraform plan

# 5. 적용
terraform apply -auto-approve
```

---

## 📝 환경별 차이점

| 항목 | DEV | STAGE | PROD |
|------|-----|-------|------|
| NAT Gateway | 1 | 1 | 2+ (Multi-AZ) |
| EKS Node 수 | 2 | 2-3 | 3-5 |
| RDS | db.t3.medium | db.t3.medium | db.r6g.large |
| Valkey | cache.t3.medium | cache.t3.medium | cache.r6g.large |
| 삭제 보호 | ❌ | ❌ | ✅ |

---

> **마지막 업데이트**: 2026-01-03
