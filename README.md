# my-claude-skills

Claude Code의 외부 스킬 저장소를 수집·설치하고, 전역 설정(`~/.claude/`)을 버전 관리하는 도구입니다.

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

`~/.claude/`의 전역 설정을 레포와 동기화합니다. 관리 대상은 `CLAUDE.md`(전역 지침)와 `settings.json`입니다. `settings.local.json`은 머신 한정 권한·절대경로를 담고 있어 `.gitignore`로 제외됩니다.

```bash
./config.sh backup   # ~/.claude/ → 레포 (로컬 설정을 레포에 반영, 커밋 전 실행)
./config.sh deploy   # 레포 → ~/.claude/ (레포 설정을 새 머신에 적용)
```

`deploy`는 덮어쓰기 전에 기존 파일을 `<파일>.bak`로 백업합니다.

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
├── home/.claude/       # 버전 관리되는 전역 설정
│   ├── CLAUDE.md       # 전역 지침
│   └── settings.json   # 전역 설정
└── skills/             # 수집된 스킬 저장소들
    ├── skill-a/
    ├── skill-b/
    └── ...
```

## 스킬 저장 위치

설치된 스킬은 `~/.claude/skills/` 디렉토리에 저장됩니다.
