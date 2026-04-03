# ── Case 3: 출력 ──────────────────────────────────────────

output "ssm_parameter_names" {
  description = "생성된 SSM parameter 경로 목록"
  value       = [for k, v in aws_ssm_parameter.demo : v.name]
}

output "ssm_parameter_arns" {
  description = "생성된 SSM parameter ARN 목록"
  value       = [for k, v in aws_ssm_parameter.demo : v.arn]
}
