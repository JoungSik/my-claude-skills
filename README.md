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
./install.sh awesome-skill  # 특정 스킬·output-style만 설치
```

### 스킬 제거

```bash
./uninstall.sh              # 전체 제거
./uninstall.sh awesome-skill  # 특정 스킬·output-style만 제거
```

### 스킬 원본 업데이트

```bash
./update.sh --check            # 원본 변경 여부와 diff만 확인
./update.sh                    # 전체 스킬을 원본 최신으로 갱신
./update.sh prompt-engineering # 특정 스킬만 갱신
```

스킬과 output-style 모두 `SOURCE.md`의 저장소·경로(또는 파일)를 기준으로 원본을 받아 비교합니다. 갱신 시 `SOURCE.md`의 수집일이 오늘 날짜로 바뀌며, `SOURCE.md`에 `커스텀 변경사항` 섹션이 있는 스킬은 덮어쓰지 않고 diff만 출력합니다. 갱신 후 `./install.sh`로 로컬에 반영합니다.

### 스킬 목록 확인

```bash
./list.sh
```

## 전역 설정 관리

`~/.claude/`의 전역 설정 중 공유분만 레포로 관리합니다. 머신별 파일(`CLAUDE.md` 본문, `settings.json`의 로컬 키)은 레포가 건드리지 않습니다.

| 레포 파일 | 역할 | 동기화 |
|------|------|------|
| `home/.claude/shared.md` | 모든 머신 공통 지침 | 양방향 (backup/deploy) |
| `home/.claude/modules/*.md` | 선택 import 조각 (github-projects 등) | 양방향 |
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
@~/.claude/modules/github-projects.md   # 사용하는 모듈만
```

`github-projects.md`는 적용 조건이 있는 모듈입니다. 전역으로 import해 두고, GitHub Project를 쓰는 저장소의 CLAUDE.md(상위 디렉터리 포함)에 아래 선언을 둔 경우에만 적용됩니다:

```markdown
GitHub Project: owner <owner>, 번호 <N>
```

### 새 머신 셋업

`./config.sh deploy` → `./install.sh` 실행. CLAUDE.md가 없으면 import 라인이 포함된 템플릿이 생성됩니다. `install.sh`는 `~/.claude/shared.md`의 스킬 목록을 갱신하므로 deploy를 먼저 실행해야 합니다.

### 기존 머신 마이그레이션 (최초 1회)

1. `./config.sh deploy` 실행 — `shared.md`, `modules/`가 로컬에 복사되고, settings.json에 공유 항목이 머지됨
2. `~/.claude/CLAUDE.md`에 `@~/.claude/shared.md` 라인 추가 (deploy가 경고로 안내)
3. CLAUDE.md에서 shared.md와 중복되는 규칙 제거, 머신 고유 규칙만 남김
4. 사용하는 모듈 import 추가 (예: `github-projects.md`)

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
| eli5 | [anthropics/claude-plugins-community](https://github.com/anthropics/claude-plugins-community) | `/eli5 <주제>`로 큰 그림과 적은 글자의 HTML 설명 생성 |

## 수집된 output-style 목록

| 이름 | 원본 저장소 | 설명 |
|------|-------------|------|
| fluent-korean | [snflkd/fluent-korean](https://github.com/snflkd/fluent-korean) | 조사·어미를 생략하지 않는 명확한 한국어 문장으로 응답. `fluent-korean`(코딩 지침 유지), `fluent-korean-not-coding` 두 가지 |

`output-styles/<이름>/`의 `.md` 파일은 `./install.sh`로 `~/.claude/output-styles/`에 설치됩니다. 적용할 스타일은 `home/.claude/shared-settings.json`의 `outputStyle`로 지정하며 `./config.sh deploy` 후 새 세션부터 적용됩니다.

## 디렉토리 구조

```
my-claude-skills/
├── README.md           # 이 파일
├── CLAUDE.md           # 이 레포 자체의 Claude Code 설정
├── add.sh              # 외부 스킬 저장소 추가
├── install.sh          # 스킬 설치
├── uninstall.sh        # 스킬 제거
├── update.sh           # 스킬·output-style 원본 업데이트
├── list.sh             # 스킬 목록 확인
├── config.sh           # 전역 설정 backup/deploy
├── home/.claude/       # 버전 관리되는 공유 설정
│   ├── shared.md            # 모든 머신 공통 지침
│   ├── shared-settings.json # 공유 설정 (deploy 시 딥머지)
│   ├── modules/             # 머신별 선택 import 조각
│   └── hooks/               # 공유 훅 스크립트 (bash)
├── output-styles/      # 수집된 output-style
└── skills/             # 수집된 스킬 저장소들
    ├── skill-a/
    ├── skill-b/
    └── ...
```

## 스킬 저장 위치

설치된 스킬은 `~/.claude/skills/` 디렉토리에 저장됩니다.

- 메타 파일(`SOURCE.md`, `README.md`, `CHANGELOG.md`, `LICENSE.md`)을 제외한 스킬 디렉토리 전체가 복사됩니다
- 원본 라이선스가 고지를 요구하면 `LICENSE.md`로 함께 수집합니다. 설치 대상에서는 제외되며 `update.sh` 갱신 시에도 보존됩니다
- 설치·제거 시 `~/.claude/shared.md`의 `## 설치된 스킬` 섹션이 갱신됩니다. 레포에 반영하려면 `./config.sh backup` 후 커밋하세요
- 이 레포가 설치한 스킬은 `~/.claude/skills/.my-claude-skills-installed`에 기록되며, 전체 설치 시 이 목록에 있는 스킬만 정리 대상입니다 (`synced/` 등 다른 경로로 설치된 스킬은 보존)
