# ── Case 1: 변수 정의 ──────────────────────────────────────
# 의도적으로 sensitive = true를 사용하지 않는다
# terraform.tfvars에서 값을 읽어온다

variable "api_key" {
  description = "External API key"
  type        = string
}
