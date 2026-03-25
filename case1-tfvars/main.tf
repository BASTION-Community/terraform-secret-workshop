# ── Case 1: terraform.tfvars + .gitignore ──────────────────
# TFC를 backend로 사용한다
# terraform.tfvars에 시크릿을 평문으로 작성하고 .gitignore로 Git 추적 제외

terraform {
  cloud {
    organization = "meiko_Org"

    workspaces {
      name = "kait-terraform"
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
      Case      = "case1-tfvars"
      ManagedBy = "terraform"
    }
  }
}
