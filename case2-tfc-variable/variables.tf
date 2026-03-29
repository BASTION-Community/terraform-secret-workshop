# ── Case 2: 변수 정의 (sensitive = true) ───────────────────
# sensitive = true로 마킹하면 terraform plan/apply 출력에서 값이 가려진다
# 하지만 State에는 여전히 평문으로 저장된다!
#
# TFC workspace variable UI에서 값을 설정하고 sensitive 체크한다
# terraform.tfvars 파일이 필요 없다 — 이것이 Case 1과의 차이점

variable "api_key" {
  description = "External API key"
  type        = string
  nullable  = false
  sensitive   = true
}