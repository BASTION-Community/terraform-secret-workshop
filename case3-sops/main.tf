# ── Case 3: SOPS + ephemeral + value_wo (Zero-Secret) ──────
# SOPS provider로 KMS 암호화 파일을 복호화하고
# ephemeral 리소스 + value_wo로 State에서도 평문을 제거한다

terraform {
  cloud {
    organization = "Meiko_Org"

    workspaces {
      name = "kait-terraform"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.3.0"
    }
  }

  # ephemeral 리소스는 Terraform 1.11+ 필요
  required_version = ">= 1.11.0"
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Project   = "terraform-secret-workshop"
      Case      = "case3-sops"
      ManagedBy = "terraform"
    }
  }
}
