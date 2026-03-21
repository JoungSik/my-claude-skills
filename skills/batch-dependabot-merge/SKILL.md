---
name: batch-dependabot-merge
description: Use when merging multiple Dependabot PRs at once - creates a work branch, rebases Dependabot PRs onto it, runs tests, and merges to main
---

# Batch Dependabot Merge

## Overview

Dependabot PR을 일괄로 머지하는 워크플로우. 개별 머지 대신 작업 브랜치에 모아서 테스트 후 main에 반영한다.

**Core principle:** PR 조회 → 작업 브랜치 생성 → base 변경 후 머지 → 테스트 → main 머지

**Announce at start:** "batch-dependabot-merge 스킬을 사용하여 Dependabot PR을 일괄 처리합니다."

## Step 1: Dependabot PR 목록 조회

열려 있는 Dependabot PR을 확인한다.

```bash
gh pr list --search "author:app/dependabot" --state open
```

- PR이 없으면 사용자에게 알리고 종료
- PR 목록을 사용자에게 보여주고 처리할 PR 확인

## Step 2: 작업 브랜치 생성 및 PR 생성

```bash
git checkout main
git pull origin main
git checkout -b feature/dependency-updates
git push -u origin feature/dependency-updates
gh pr create --title "chore: batch dependency updates" --body "Dependabot PR 일괄 적용"
```

## Step 3: Dependabot PR base branch 변경 후 머지

각 Dependabot PR의 base를 작업 브랜치로 변경하고 머지한다.

```bash
# 각 PR에 대해 반복
gh pr edit <PR번호> --base feature/dependency-updates
gh pr merge <PR번호> --merge
```

- 충돌 발생 시 사용자에게 알리고 해당 PR은 건너뛸지 확인
- 모든 PR 처리 후 로컬에 pull

```bash
git pull origin feature/dependency-updates
```

## Step 4: 테스트 실행

로컬에서 테스트를 실행하여 의존성 업데이트가 문제없는지 확인한다.

- 프로젝트의 테스트 명령 실행 (예: `bundle exec rails test`, `npm test` 등)
- 테스트 실패 시 사용자에게 보고하고 수정 방향 논의

## Step 5: main 머지

테스트 통과 확인 후 작업 브랜치 PR을 main에 머지한다.

```bash
gh pr merge <작업브랜치PR번호> --merge
```

- 머지 후 로컬 정리:

```bash
git checkout main
git pull origin main
git branch -d feature/dependency-updates
```

## 주의사항

- main 브랜치에 직접 머지하지 않는다. 반드시 작업 브랜치 → PR → 테스트 → 머지 흐름을 따른다
- 충돌이 있는 PR은 무시하지 말고 사용자에게 확인받는다
- 테스트 통과 전에 main 머지를 제안하지 않는다
