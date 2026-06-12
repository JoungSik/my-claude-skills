# 전역 Claude 설정 선택적 공유 설계

날짜: 2026-06-12

## 배경

기존 `config.sh`는 `~/.claude/CLAUDE.md`와 `settings.json`을 통째로 backup/deploy하는 방식이었다. 그러나 두 파일에는 범용 항목(언어 규칙, Git 규칙, 서브에이전트 모델 선택 등)과 머신/직장 특화 항목(stayfolio 마켓플레이스, 이슈 트래커 MCP 규칙 등)이 섞여 있어, 전체 복사로는 머신 간 공유가 부적합하다. 전역적으로 적용 가능한 항목만 추출해 공유하도록 재설계한다.

## 구조

### 레포

```
home/.claude/
├── shared.md              # 모든 머신 공통 지침 (항상 import)
├── shared-settings.json   # 공유 설정 (deploy 시 딥머지)
├── modules/               # 선택 import 조각 (deploy 시 전부 복사)
│   ├── redmine.md         # Redmine MCP 포맷 규칙 + 계획 승인 후 이슈 처리
│   └── linear.md          # Linear MCP 계획 승인 후 이슈 처리
└── hooks/                 # 공유 훅 스크립트 (bash)
```

기존 `home/.claude/CLAUDE.md`, `home/.claude/settings.json`(전체 사본)은 삭제한다. 레포에는 공유분만 존재한다.

### 로컬 (`~/.claude/`)

```
~/.claude/
├── CLAUDE.md          # 머신별 파일. 레포가 내용을 관리하지 않음
├── shared.md          # 레포와 동기화
├── modules/           # 레포와 동기화 (import 여부는 머신별 선택)
├── hooks/             # 레포와 동기화 (실행 여부는 settings의 hooks 등록으로 결정)
└── settings.json      # 머신별 파일. deploy 시 공유 항목만 딥머지
```

각 머신의 `CLAUDE.md`는 `@~/.claude/shared.md`를 항상 import하고, 사용하는 모듈만 추가로 import한다. import되지 않은 모듈 파일은 Claude가 읽지 않으므로 전 머신에 복사돼도 무해하다.

- 회사 PC: `@~/.claude/shared.md` + `@~/.claude/modules/linear.md`
- Redmine 사용 머신: `@~/.claude/shared.md` + `@~/.claude/modules/redmine.md`

## config.sh 동작

### backup (공유 규칙을 수정한 머신에서, 커밋 전 실행)

1. `~/.claude/shared.md` → `home/.claude/shared.md`
2. `~/.claude/modules/*.md` → `home/.claude/modules/`
3. `~/.claude/hooks/*.sh` → `home/.claude/hooks/`
4. settings는 backup 없음 — `shared-settings.json` 직접 편집이 유일한 수정 경로

### deploy (새 머신 셋업 또는 공유 규칙 갱신)

1. **shared.md / modules/ / hooks/**: 기존 로컬 파일과 내용이 다르면 `.bak`로 백업 후 레포 파일로 덮어쓰기 (실행 권한 유지)
2. **CLAUDE.md 점검** (내용 수정 없음):
   - 파일 없음 → `@~/.claude/shared.md` import 라인이 든 최소 템플릿 생성
   - import 라인 없음 → 추가할 라인을 안내하는 경고 출력 (기존 머신 마이그레이션 유도)
3. **settings.json 딥머지**:
   - `shared-settings.json` JSON 유효성 검증, 실패 시 로컬 미변경 상태로 중단
   - 로컬 파일 없으면 공유 내용으로 생성
   - 있으면 머지 결과의 변경 항목을 diff로 출력 → `.bak` 백업 → 기록. 변경 없으면 쓰기 생략
   - 머지 규칙: `jq -s '.[0] * .[1]'` (객체 재귀 머지, 공유 값 우선, 로컬 전용 키 유지)

### 정책

- 의존성: `jq` 필수(macOS 기본 탑재), 없으면 설치 안내 후 종료
- `.bak`는 다음 deploy 때 덮어써질 뿐 스크립트가 삭제하지 않음 (1단계 undo 용도). `settings.json.bak`가 실질적 안전망 (로컬 settings는 어디에도 버전 관리되지 않으므로)
- 실패 처리: 검증 → 백업 → 쓰기 순서로 절반만 수정된 상태를 만들지 않음
- 훅 컨벤션: 공유 훅은 bash로 작성, JSON 파싱은 jq 사용 (추가 런타임 의존 금지)
- 머지 캐비앗: jq `*` 머지는 배열을 통째로 교체하므로, 같은 훅 이벤트의 항목은 공유/로컬 중 한쪽으로만 관리

## 초기 내용 분류

| 항목 | 위치 |
|------|------|
| 언어, Git 필수 규칙, Context7, 서브에이전트 모델 선택, 설치된 스킬 | `shared.md` |
| Redmine MCP 포맷 규칙 + 계획 승인 후 이슈 처리 (구버전 사본에서 복원) | `modules/redmine.md` |
| 계획 승인 후 이슈 처리 (Linear MCP용 변환, 포맷 규칙 불필요) | `modules/linear.md` |
| env 플래그, ruby-lsp/gopls 플러그인 | `shared-settings.json` |
| model, theme, effortLevel, 타임스탬프, stayfolio 마켓플레이스/플러그인 | 공유 제외 (로컬 유지) |

## 마이그레이션

### 이 머신 (회사 PC)

1. 레포에 `shared.md`, `shared-settings.json`, `modules/`, `hooks/` 생성, 기존 전체 사본 삭제
2. `config.sh` 재작성
3. `deploy` 실행·검증
4. 로컬 `CLAUDE.md`를 import 두 줄(`shared.md`, `modules/linear.md`)로 교체
5. README 갱신 후 커밋

### 다른 PC

pull → `deploy` → 안내에 따라 CLAUDE.md에 import 라인 추가 + shared.md와 중복되는 규칙 제거. Redmine 사용 머신이면 `@~/.claude/modules/redmine.md`도 추가.
