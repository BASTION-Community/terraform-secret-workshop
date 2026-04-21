# ── Case 2: TFC workspace variable + sensitive ─────────────
# Terraform Cloud를 backend로 사용하고
# workspace variable에 시크릿을 등록한다

terraform {
  cloud {
    organization = "YOUR_ORG"

    workspaces {
      name = "YOUR_WORKSPACE"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95.0"
    }
  }

  required_version = ">= 1.6.0"
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Project   = "terraform-secret-workshop"
      Case      = "case2-tfc-variable"
      ManagedBy = "terraform"
    }
  }
}
