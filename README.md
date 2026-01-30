# my-claude-skills

외부 Claude Code 스킬 저장소를 수집하고 일괄 설치하는 관리 도구입니다.

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

## 수집된 스킬 목록

| 이름 | 원본 저장소 | 설명 |
|------|-------------|------|
| prompt-engineering | [NeoLabHQ/context-engineering-kit](https://github.com/NeoLabHQ/context-engineering-kit) | 프롬프트 엔지니어링 및 에이전트 커뮤니케이션 가이드 |
| skill-creator | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | 효과적인 스킬 생성 가이드 |
| software-architecture | [NeoLabHQ/context-engineering-kit](https://github.com/NeoLabHQ/context-engineering-kit) | Clean Architecture 및 DDD 기반 소프트웨어 아키텍처 가이드 |
| subagent-driven-development | [NeoLabHQ/context-engineering-kit](https://github.com/NeoLabHQ/context-engineering-kit) | 서브에이전트 기반 개발 - 독립 작업을 병렬로 실행 |
| terminal-title | [bluzername/claude-code-terminal-title](https://github.com/bluzername/claude-code-terminal-title) | 터미널 창 제목 자동 업데이트 |
| review-implementing | [mhattingpete/claude-skills-marketplace](https://github.com/mhattingpete/claude-skills-marketplace) | 코드 리뷰 피드백 체계적 처리 및 구현 |

## 디렉토리 구조

```
my-claude-skills/
├── README.md           # 이 파일
├── CLAUDE.md           # Claude Code 프로젝트 설정
├── add.sh              # 외부 스킬 저장소 추가
├── install.sh          # 스킬 설치
├── uninstall.sh        # 스킬 제거
├── list.sh             # 스킬 목록 확인
└── skills/             # 수집된 스킬 저장소들
    ├── skill-a/
    ├── skill-b/
    └── ...
```

## 스킬 저장 위치

설치된 스킬은 `~/.claude/skills/` 디렉토리에 저장됩니다.
