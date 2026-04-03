# ── KMS Key for SOPS ───────────────────────────────────────
# SOPS envelope encryption에 사용되는 KMS CMK
# 이 키가 있어야 SOPS 파일을 암호화/복호화할 수 있다

resource "aws_kms_key" "sops" {
  description         = "SOPS secret encryption for workshop demo"
  enable_key_rotation = true

  tags = {
    purpose = "sops"
  }
}

resource "aws_kms_alias" "sops" {
  name          = "alias/demo-sops"
  target_key_id = aws_kms_key.sops.key_id
}

# ── 출력: .sops.yaml에 입력할 KMS ARN ──
output "kms_key_arn" {
  description = "KMS Key ARN — .sops.yaml의 kms 필드에 입력"
  value       = aws_kms_key.sops.arn
}

output "kms_alias" {
  description = "KMS Key Alias"
  value       = aws_kms_alias.sops.name
}
