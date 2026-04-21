# Workspace Alignment Review

Terraform Cloud workspace 설정이 문서와 코드에서 서로 다르게 표현되던 부분을 정리한 문서다.
발표 전에 어떤 점이 헷갈렸고, 지금 어떤 기준으로 맞추는 것이 자연스러운지 한 번에 확인할 수 있게 정리했다.

## 문제가 된 지점

| 위치 | 기존 표현 | 문제 |
|------|-----------|------|
| `README.md` | 세 Case 모두 `secret-workshop` 사용 | 하나의 TFC workspace가 세 개의 working directory를 동시에 대표하는 것처럼 읽힌다 |
| `case1-tfvars/README.md` | `secret-workshop-case1` | 루트 README와 다름 |
| `case2-tfc-variable/README.md` | `secret-workshop-case2` | 루트 README와 다름 |
| `case3-sops/README.md` | `secret-workshop-case3` | 루트 README와 다름 |
| `case1-tfvars/main.tf` | `YOUR_WORKSPACE` | placeholder 패턴 |
| `case2-tfc-variable/main.tf` | `secret-workshop-case2` | README의 예시 이름이 코드에 하드코딩됨 |
| `case3-sops/main.tf` | `kait-terraform` | 다른 Case와 전혀 다른 실제 workspace 값이 들어 있음 |

## 왜 헷갈렸는가

1. 루트 README는 "하나의 workspace로 세 Case를 돌리는 구조"처럼 보였다.
2. 개별 Case README는 "Case마다 별도 workspace를 만든다"는 구조였다.
3. 실제 Terraform 코드(`main.tf`)는 어떤 곳은 placeholder, 어떤 곳은 예시 이름, 어떤 곳은 실제 개인 환경 값이 섞여 있었다.

이 조합이면 발표자는 이해하고 있어도, 저장소를 처음 clone한 사람은 "정답이 무엇인지"를 판단하기 어렵다.

## 권장 기준

권장 기준은 아래 두 줄로 요약된다.

- 문서는 **Case마다 별도 workspace를 하나씩 만든다**고 설명한다.
- 코드는 특정 이름을 강제하지 않고 `YOUR_ORG`, `YOUR_WORKSPACE` placeholder를 사용한다.

이 기준이 좋은 이유는 다음과 같다.

- TFC workspace는 일반적으로 하나의 working directory와 하나의 state 흐름을 가진다.
- Case 1, 2, 3은 비교 실습이므로 state와 실행 이력을 분리하는 편이 설명도 쉽고 rollback도 단순하다.
- 발표자와 참가자가 각자 원하는 naming convention을 써도 코드 수정 범위가 작다.

## 권장 workspace 매핑

아래 이름은 "필수값"이 아니라 발표/워크숍에서 설명하기 쉬운 **권장 예시**다.

| Workspace | Working Directory | 용도 |
|-----------|-------------------|------|
| `secret-workshop-case1` | `case1-tfvars` | tfvars + `.gitignore` 실습 |
| `secret-workshop-case2` | `case2-tfc-variable` | TFC variable + `sensitive` 실습 |
| `secret-workshop-case3` | `case3-sops` | SOPS + `ephemeral` + `value_wo` 실습 |

## 이번 정리에서 반영한 내용

- 루트 README의 workspace 표기를 Case별 분리 방식으로 수정
- `case2-tfc-variable/main.tf`의 workspace 하드코딩 제거
- `case3-sops/main.tf`의 organization/workspace 하드코딩 제거
- 각 README의 실행 가이드에서 `organization`뿐 아니라 `workspace`도 직접 채우도록 안내

## 남겨둔 의도적 선택

문서에는 권장 workspace 이름을 적어두었지만, Terraform 코드에는 특정 이름을 하드코딩하지 않았다.
즉, 발표 자료에서는 `secret-workshop-case1/2/3`를 예시로 설명하고, 실제 코드는 참가자가 자신의 naming rule을 넣는 방식으로 가져가면 된다.
