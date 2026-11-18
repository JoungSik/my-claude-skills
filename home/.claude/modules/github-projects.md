# GitHub Projects 작업 규칙

## 적용 조건
- 저장소 CLAUDE.md(상위 디렉터리 포함)에 아래 선언이 있을 때만 적용. 없으면 이 문서 전체를 무시함
  - `GitHub Project: owner <owner>, 번호 <N>`
- 필드·옵션 ID는 기록하지 않고 조회함: `gh project field-list <N> --owner <owner> --format json`

## 이슈 생성
- 코드가 있는 저장소에 생성. Draft item과 저장소 없는 작업은 등록하지 않음
- 작업 1개 = 이슈 1개. sub-issue 미사용
  - 독립적으로 머지·배포 가능한 단위로 나눔. 단독 머지 시 기능이 완결되지 않으면 나누지 않음
  - 관련 이슈는 `## 참고`에 `관련 이슈: #번호`
- 본문: `## 배경` / `## 작업 내용`(체크리스트) / `## 완료 기준` / `## 참고`. 실제 코드·README 확인 후 작성
- 생성 직후 `gh project item-add <N> --owner <owner> --url <이슈 URL>`. Auto-add에 의존하지 않음
- 추가 후 Status가 비어 있으면 `Todo`로 설정

## 이슈 번호로 착수
1. `gh issue view <번호> --comments`로 본문·댓글 확인. 승인된 계획 댓글이 있으면 그 계획을 기준으로 함
2. 이슈가 closed이거나 연결된 PR이 있으면 착수 전 보고
3. 코드 확인 → 계획 작성 → 사용자 승인
4. 승인 후 계획 전문을 이슈 댓글로 등록, Status를 `In Progress`로 변경
5. `feature/<작업-설명>` 브랜치 → 구현 → 테스트 → PR

## 브랜치와 PR 연결
- `develop` 브랜치가 있으면 develop 흐름, 없으면 기본 브랜치 단일 흐름
- 기본 브랜치 대상 PR: 본문에 `Closes #N` 필수(다른 저장소는 `Closes <owner>/<repo>#N`). `#N`, `Refs #N`은 닫기 연결이 아님
- 기본 브랜치가 아닌 대상 PR(develop, 릴리스 브랜치): Closes가 연결되지 않음. 이슈는 기본 브랜치 반영 시점에 닫힘
  - 경로 1: 릴리스 PR 본문에 `Closes` 목록 기재
  - 경로 2: 저장소 머지 커밋 메시지 설정. develop PR의 Closes가 머지 커밋에 남아 main 반영 시 닫힘
    `gh api --method PATCH repos/<owner>/<repo> -f merge_commit_title=PR_TITLE -f merge_commit_message=PR_BODY`
- 봇(GITHUB_TOKEN, App 토큰)이 작성·수정한 PR 본문의 Closes는 연결되지 않음

## 머지 후 완료 확인
- 기본 브랜치 반영 직후 확인. develop 흐름은 릴리스 PR 머지 후 확인
  - 이슈: `gh issue view <N> --json state`
  - Status: `gh project item-list <N> --owner <owner> --format json`
- 이슈가 열려 있으면 원인 보고 후 즉시 close
  - `gh issue close <N> --comment "PR #<M> 머지로 완료"`
- Status가 `Done`이 아니면 `Done`으로 설정

## Status 처리
- 전환 시점: Project 추가 → `Todo`, 계획 승인 → `In Progress`, PR 연결 → `In Review`, 완료 → `Done`
- 각 시점에 실제 값을 확인하고, 자동으로 전환되지 않았으면 수동으로 설정
- develop 대상 PR은 이슈 연결이 없어 `In Review`로 자동 전환되지 않음

## develop 흐름을 새 저장소에 적용할 때
1. `develop` 브랜치 생성, Dependabot `target-branch: develop`
2. CI 트리거를 `pull_request: branches: [ main ]`으로 제한
3. 머지 커밋 메시지 설정(위 경로 2)
