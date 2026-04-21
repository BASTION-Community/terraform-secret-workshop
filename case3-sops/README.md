# Case 3: SOPS + ephemeral + value_wo (Zero-Secret)

## 실습 목표

- SOPS(KMS envelope encryption)로 시크릿을 암호화하여 **Git에 안전하게 커밋**하는 방법을 이해한다
- `ephemeral` 리소스와 `value_wo` 속성으로 **State에서도 평문을 제거**하는 패턴을 실습한다
- `versions.yaml`로 **value_wo_version을 관리**하는 패턴을 이해한다
- Case 1, 2와 `terraform state pull` 결과를 비교하여 Zero-Secret을 검증한다

## case3 의 흐름

![img.png](images/img1.png)

## Case 1, 2와의 차이점

| 항목 | Case 1 (tfvars) | Case 2 (TFC variable) | Case 3 (SOPS) |
|------|----------------|---------------------|-------------|
| 시크릿 저장 | 로컬 파일 | TFC SaaS | **Git (암호화)** |
| SSM 리소스 | 1개 | 1개 | **3개** (for_each + versions.yaml) |
| State 평문 | 평문 | 평문 | **빈 문자열** |
| 값 변경 감지 | 자동 | 자동 | **versions.yaml bump** |

## 사전 준비

- AWS 계정 + 자격증명 (KMS, SSM 권한)
- Terraform CLI >= **1.11** (ephemeral 리소스 지원)
- TFC 계정 + workspace
- SOPS CLI (`brew install sops`)
- jq
- 로컬 `AWS_PROFILE` 또는 기본 자격증명으로 KMS `Encrypt`가 가능해야 함

> 핸즈온 진행은 workspace의 **Environment variables**에 `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`를 넣는 것이다.
> 발표자나 운영 환경에서만 필요하면 OIDC/Dynamic Credentials를 사용해도 되며, 이 경우 `TFC_AWS_PROVIDER_AUTH`, `TFC_AWS_RUN_ROLE_ARN`은 **Environment variable**이어야 한다.

## 실습 절차

### Step 1: KMS Key 생성 (1st apply)

```bash
# main.tf의 organization, workspace를 본인 TFC 값으로 수정 후
terraform init

# SOPS 에서 사용할 KMS Key만 먼저 생성
terraform plan -target='aws_kms_key.sops' -target='aws_kms_alias.sops'
terraform apply -target='aws_kms_key.sops' -target='aws_kms_alias.sops' -auto-approve

# KMS ARN 확인
terraform output kms_key_arn
# → arn:aws:kms:ap-northeast-2:123456789012:key/abcd-1234-...
```

### Step 2: SOPS 파일 생성

```bash
# SOPS 암호화는 로컬 AWS 자격증명으로 KMS Encrypt를 호출한다.
# HCP Terraform workspace 변수와 별개로 로컬 credential이 필요하다.
# 필요하면 예: export AWS_PROFILE=temp-meiko

# secrets/ 안에서 작업한다
cd secrets

# .sops.yaml은 sops가 자동 생성하지 않는다.
# secrets/ 안에 템플릿을 복사해 직접 만든다.
cp .sops.yaml.example .sops.yaml

# terraform output -raw kms_key_arn 결과를 .sops.yaml의 kms 값에 붙여넣는다
# 예: kms: "arn:aws:kms:ap-northeast-2:123456789012:key/abcd-1234-..."

# 평문 예시를 복사하여 실제 SOPS 파일 생성
cp demo.yaml.example demo.yaml

# path_regex는 .sops.yaml 위치 기준으로 평가된다.
# .sops.yaml이 secrets/ 안에 있으므로 demo.yaml에 맞게 설정되어 있어야 한다.

# SOPS로 암호화 (로컬 AWS 자격증명에 KMS Encrypt 권한 필요)
sops --encrypt --in-place demo.yaml

# 암호화 확인 — 값이 ENC[AES256_GCM,...] 형태로 변환됨
cat demo.yaml

# 복호화 테스트 — KMS 권한이 있으면 평문으로 출력
sops -d demo.yaml

# 이후 terraform 명령을 위해 루트로 복귀
cd ..
```

### Step 3: SSM Parameter 생성 (2nd apply)

```bash
# case3-sops/ 루트에서 실행
terraform plan
terraform apply -auto-approve

# 예상 출력:
# Plan: 3 to add, 0 to change, 0 to destroy.
# ephemeral.sops_file.demo: Opening...
# ephemeral.sops_file.demo: Closing...
# aws_ssm_parameter.demo["/demo/api-key-1"]: Creating...
# aws_ssm_parameter.demo["/demo/api-key-2"]: Creating...
# aws_ssm_parameter.demo["/demo/api-key-3"]: Creating...
```

#### apply 로그에서 `ephemeral.sops_file.demo: Opening...`은 무슨 뜻인가?

이 로그는 `ephemeral "sops_file" "demo"` 블록이 실제로 동작하고 있다는 뜻이다.

![img.png](images/img.png)

로그의 의미

- `Opening...`
  `secrets/demo.yaml`을 읽고 복호화해서 평문 데이터를 **메모리에 준비하는 단계**
- `Opening complete after 2s`
  복호화와 로딩이 끝나서 Terraform이 그 값을 사용할 수 있게 된 상태
- `Closing...`
  `aws_ssm_parameter.demo`에 값을 전달한 뒤 더 이상 필요 없어진 상태
- `Closing complete after 0s`
  ephemeral 값 정리가 끝난 상태

결론

- 이 값은 `value_wo`로 SSM에 전달될 때만 잠깐 쓰인다
- 그래서 apply 로그에는 `Opening`과 `Closing`이 보이지만, state에는 평문이 남지 않는다

### Step 4: SSM 확인 (정상 주입)

```bash
# aws console 에서 확인

# 또는 aws cli
aws ssm get-parameter --name "/demo/api-key-1" --with-decryption \
  --query "Parameter.Value" --output text
# → test1234 (정상)
```

### Step 5: State 검증 (Zero-Secret!)

```bash
# state show — "write-only attribute"로 표시
terraform state show 'aws_ssm_parameter.demo["/demo/api-key-1"]'
# → value_wo = (write-only attribute)

# state pull — 빈 문자열! 평문 없음!
terraform state pull | jq '.resources[] | select(.type=="aws_ssm_parameter") | .instances[].attributes | {name, value}'
# → { "name": "/demo/api-key-1", "value": ""}
# → { "name": "/demo/api-key-2", "value": ""}
# → { "name": "/demo/api-key-3", "value": ""}
```

**Case 1, 2와 비교:**

| 확인 방법 | Case 1 (tfvars) | Case 2 (sensitive) | Case 3 (SOPS) |
|----------|----------------|-------------------|--------------|
| state show | `(sensitive value)` | `(sensitive value)` | `(write-only attribute)` |
| state pull | **`"test1234"`** | **`"test1234"`** | **`""`** |

### Step 6: 값 변경 시나리오 (value_wo_version)

```bash
# 1. SOPS 파일에서 값 수정
cd secrets
sops demo.yaml
# 에디터에서 /demo/api-key-1 의 값을 변경
cd ..

# 2. 아직 versions.yaml은 건드리지 않고 먼저 plan 확인
terraform plan
# → No changes. Your infrastructure matches the configuration.

# 3. versions.yaml에서 해당 키의 버전 bump
# "/demo/api-key-1": 1  →  "/demo/api-key-1": 2

# 4. 다시 terraform plan → 이제 변경 감지
terraform plan
# ~ aws_ssm_parameter.demo["/demo/api-key-1"]
#     ~ value_wo_version = 1 → 2
```

왜 처음에는 `No changes`가 뜰까?

- `value_wo`는 write-only라서 state에 저장되지 않는다
- 따라서 Terraform은 **이전 값이 무엇이었는지 비교할 기준**이 없다
- 즉, SOPS 파일 안의 평문이 바뀌어도 Terraform 입장에서는 추적 가능한 diff가 없다
- 그래서 사람이 `value_wo_version`을 올려서 “이 값이 바뀌었으니 다시 보내라”고 알려줘야 한다

### Step 7: 정리

```bash
# 1. 자원 삭제
terraform destroy -auto-approve

# aws console
# 2. access key 제거

# 3. terraform cloud logout
terraform logout
```

## 주요 개념

### versions.yaml — value_wo_version 관리

```yaml
# versions.yaml
"/demo/api-key-1": 1    # 값 변경 시 → 2로 bump
"/demo/api-key-2": 1
"/demo/api-key-3": 1
```

- `value_wo`는 State에 없으므로 Terraform이 값 변경을 자동 감지할 수 없다
- `versions.yaml`에서 해당 키의 숫자를 +1하면 `value_wo_version`이 변경되어 apply 트리거
- **시크릿 추가 시**: versions.yaml에 새 키 추가 + SOPS 파일에 값 추가 → `terraform plan` → N to add

### for_each 패턴

```hcl
resource "aws_ssm_parameter" "demo" {
  for_each = local.versions                                    # versions.yaml의 map

  name             = each.key                                  # "/demo/api-key-1"
  value_wo         = ephemeral.sops_file.demo.data[each.key]   # 메모리의 평문
  value_wo_version = each.value                                # 1, 2, 3...
}
```

versions.yaml이 `for_each`의 source of truth — 시크릿 추가/삭제가 이 파일 하나로 관리된다.

## 검증 결과

| 확인 항목 | 결과 |
|----------|------|
| Git | **암호화** 상태로 커밋 (ENC[AES256_GCM,...]) |
| 로컬 파일 | 암호화됨 (KMS 없이 복호화 불가) |
| terraform plan | `value_wo = (write-only attribute)` |
| terraform state pull | **빈 문자열** — 평문 없음 (3개 모두) |
| AWS SSM | SecureString으로 **정상 저장** |

## Case 1/2의 문제가 어떻게 해결되는가

| 이전 문제       | Case 3의 해결 |
|-------------|-------------|
| 로컬/State 평문 | ephemeral + value_wo → **메모리에서만 존재** |
| 팀 공유 불편     | SOPS 파일을 **Git으로 공유** (암호화 상태) |
| 버전 관리 불가    | **Git diff**로 시크릿 변경 이력 추적 |
| SaaS 의존성 탈피 | 자체 KMS 키 — TFC 없이도 동작 가능 |
| 비용          | KMS API 호출 비용만 (~$0.03/10,000건) |
