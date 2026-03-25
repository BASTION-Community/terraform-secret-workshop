# ── Case 1: SSM Parameter Store ────────────────────────────
# terraform.tfvars의 값을 SSM SecureString으로 저장한다
# value = var.XXX → State에 평문이 저장된다

resource "aws_ssm_parameter" "api_key" {
  name  = "/demo/api-key"
  type  = "SecureString"
  value = var.api_key
}
