# ── Case 2: SSM Parameter Store ────────────────────────────
# Case 1과 동일한 코드! value = var.XXX 패턴
# sensitive = true가 추가되었지만 State 저장 방식은 동일하다

resource "aws_ssm_parameter" "api_key" {
  name  = "/demo/api-key"
  type  = "SecureString"
  value = var.api_key
}
