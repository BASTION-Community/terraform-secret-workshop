# ── Case 3: SSM Parameter Store (Zero-Secret 패턴) ─────────
# ephemeral "sops_file" — 메모리에서만 존재, State에 미기록
# value_wo — SSM에 평문 전달, State에 빈 문자열 저장
# value_wo_version — 값 변경 시 수동 bump (Terraform이 변경을 감지하도록)

# ── 버전 메타데이터 로드 ──
locals {
  versions = yamldecode(file("${path.module}/secrets/versions.yaml"))
}

# ── SOPS 복호화 (ephemeral — State에 기록되지 않음) ──
ephemeral "sops_file" "demo" {
  source_file = "${path.module}/secrets/demo.yaml"
}

# ── SSM Parameter 생성 ──
resource "aws_ssm_parameter" "demo" {
  for_each = local.versions

  name             = each.key # SSM path (예: /demo/db/password)
  type             = "SecureString"
  value_wo         = ephemeral.sops_file.demo.data[each.key] # 메모리의 평문 → SSM에 전달
  value_wo_version = each.value                              # 값 변경 시 이 숫자를 bump

  tags = {
    managed_by = "sops"
  }
}
