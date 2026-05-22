# AGENTS.md

## Collaboration

- 도중에 결정이 필요하거나 애매한 부분이나 맥락을 모르거나 궁금한 점이 있으면 먼저 질문한다.
- 이 repo의 아키텍처 기본값을 바꾸는 변경은 사용자 확인 없이 진행하지 않는다.
- 구조 변경 전에는 관련 문서를 먼저 읽고, 문서와 충돌하면 먼저 질문한다.

## Repo Role

- 이 repo는 Cloudflare Terraform, Kubernetes manifests, GitOps(Argo CD) 설정을 관리한다.
- 앱 소스 코드는 sibling repo `../litomi`에 있다.

## Cloudflare

- Cloudflare는 Free plan을 사용한다.
- Cloudflare 관련 보안/캐시/라우팅 제안은 Free plan에서 가능한 기능을 우선 고려한다.
