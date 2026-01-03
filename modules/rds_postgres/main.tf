# RDS PostgreSQL Module: 메인 리소스

# 랜덤 비밀번호 생성
resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager 이름 충돌 방지용 랜덤 접미사
resource "random_id" "secret_suffix" {
  byte_length = 4
}

# Secrets Manager에 비밀번호 저장
# 이름에 랜덤 접미사 추가하여 삭제 후 재생성 시 충돌 방지
resource "aws_secretsmanager_secret" "rds" {
  name                    = "${var.name_prefix}-rds-creds-${random_id.secret_suffix.hex}"
  description             = "RDS PostgreSQL credentials for ${var.name_prefix}"
  recovery_window_in_days = 0 # 즉시 삭제 허용 (DEV 환경용)

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.name_prefix}-rds"

  # Engine
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.main.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = random_password.master.result

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false
  port                   = 5432

  # Availability
  multi_az = var.multi_az

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # Security
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  # Monitoring
  performance_insights_enabled = true

  # Upgrades
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds"
  })

  lifecycle {
    ignore_changes = [password]
  }
}
