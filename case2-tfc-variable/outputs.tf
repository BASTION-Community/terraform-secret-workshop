# ── Case 2: 출력 ──────────────────────────────────────────

output "ssm_parameter_name" {
  description = "생성된 SSM parameter 경로"
  value       = aws_ssm_parameter.api_key.name
}

output "ssm_parameter_arn" {
  description = "생성된 SSM parameter ARN"
  value       = aws_ssm_parameter.api_key.arn
}
