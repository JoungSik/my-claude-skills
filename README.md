# my-claude-skills

Claude Code의 외부 스킬 저장소를 수집·설치하고, 전역 설정(`~/.claude/`) 중 **머신 간 공유 가능한 항목만** 버전 관리하는 도구입니다.

## 사용법

### 외부 스킬 저장소 추가

```bash
./add.sh <저장소URL> [폴더명]

# 예시
./add.sh https://github.com/someone/awesome-skill
./add.sh https://github.com/someone/awesome-skill my-custom-name
```

### 스킬 설치

```bash
./install.sh              # 전체 설치
./install.sh awesome-skill  # 특정 스킬만 설치
```

### 스킬 제거

```bash
./uninstall.sh              # 전체 제거
./uninstall.sh awesome-skill  # 특정 스킬만 제거
```

### 스킬 목록 확인

```bash
./list.sh
```

## 전역 설정 관리

`~/.claude/`의 전역 설정 중 공유분만 레포로 관리합니다. 머신별 파일(`CLAUDE.md` 본문, `settings.json`의 로컬 키)은 레포가 건드리지 않습니다.

| 레포 파일 | 역할 | 동기화 |
|------|------|------|
| `home/.claude/shared.md` | 모든 머신 공통 지침 | 양방향 (backup/deploy) |
| `home/.claude/modules/*.md` | 머신별 선택 import 조각 (linear, redmine 등) | 양방향 |
| `home/.claude/hooks/*.sh` | 공유 훅 스크립트 | 양방향 |
| `home/.claude/shared-settings.json` | 공유 설정 | deploy만 (레포 파일 직접 편집) |

```bash
./config.sh backup   # ~/.claude/ → 레포 (공유 규칙 수정 후, 커밋 전 실행)
./config.sh deploy   # 레포 → ~/.claude/ (공유 파일 복사 + settings.json 딥머지)
```

각 머신의 `~/.claude/CLAUDE.md`는 공유 지침을 import하고, 사용하는 모듈만 선택해서 추가합니다:

```markdown
# Global Claude Code Instructions

@~/.claude/shared.md
@~/.claude/modules/linear.md   # 이 머신이 쓰는 이슈 트래커 모듈만
```

### 새 머신 셋업

`./install.sh` → `./config.sh deploy` 실행. CLAUDE.md가 없으면 import 라인이 포함된 템플릿이 생성됩니다.

### 기존 머신 마이그레이션 (최초 1회)

1. `./config.sh deploy` 실행 — `shared.md`, `modules/`가 로컬에 복사되고, settings.json에 공유 항목이 머지됨
2. `~/.claude/CLAUDE.md`에 `@~/.claude/shared.md` 라인 추가 (deploy가 경고로 안내)
3. CLAUDE.md에서 shared.md와 중복되는 규칙 제거, 머신 고유 규칙만 남김
4. 사용하는 이슈 트래커 모듈 import 추가 (`linear.md` 또는 `redmine.md`)

### 동작 세부

- `deploy`는 덮어쓰기 전 기존 파일을 `<파일>.bak`로 백업합니다 (다음 deploy 때 덮어써지는 1세대 백업)
- settings.json 머지는 jq 딥머지(`.[0] * .[1]`)로 공유 값이 우선하되 로컬 전용 키(model, theme, 머신별 플러그인 등)는 유지됩니다
- **주의**: jq 머지는 배열을 통째로 교체하므로, 같은 훅 이벤트(`PreToolUse` 등)의 항목은 공유/로컬 중 한쪽으로만 관리하세요
- 공유 훅은 bash로 작성하고 JSON 파싱은 jq를 사용합니다 (추가 런타임 의존 금지)
- `settings.local.json`은 머신 한정 권한·절대경로를 담고 있어 관리 대상에서 제외됩니다

## 수집된 스킬 목록

| 이름 | 원본 저장소 | 설명 |
|------|-------------|------|
| prompt-engineering | [NeoLabHQ/context-engineering-kit](https://github.com/NeoLabHQ/context-engineering-kit) | 프롬프트 엔지니어링 및 에이전트 커뮤니케이션 가이드 |
| skill-creator | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | 효과적인 스킬 생성 가이드 |
| review-implementing | [mhattingpete/claude-skills-marketplace](https://github.com/mhattingpete/claude-skills-marketplace) | 코드 리뷰 피드백 체계적 처리 및 구현 |
| plan-generator | 로컬 생성 | 작업 계획 생성 및 관리 - 서브에이전트로 코드 분석 후 계획 문서 생성 |

## 디렉토리 구조

```
my-claude-skills/
├── README.md           # 이 파일
├── CLAUDE.md           # 이 레포 자체의 Claude Code 설정
├── add.sh              # 외부 스킬 저장소 추가
├── install.sh          # 스킬 설치
├── uninstall.sh        # 스킬 제거
├── list.sh             # 스킬 목록 확인
├── config.sh           # 전역 설정 backup/deploy
├── docs/plans/         # 설계 문서
├── home/.claude/       # 버전 관리되는 공유 설정
│   ├── shared.md            # 모든 머신 공통 지침
│   ├── shared-settings.json # 공유 설정 (deploy 시 딥머지)
│   ├── modules/             # 머신별 선택 import 조각
│   └── hooks/               # 공유 훅 스크립트 (bash)
└── skills/             # 수집된 스킬 저장소들
    ├── skill-a/
    ├── skill-b/
    └── ...
```

## 스킬 저장 위치

설치된 스킬은 `~/.claude/skills/` 디렉토리에 저장됩니다.
