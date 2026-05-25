# Global Claude Code Instructions

## MCP 자동 호출 규칙

### Context7 (외부 라이브러리 문서)
다음 상황에서 항상 context7 MCP를 사용할 것:
- 라이브러리, 프레임워크, gem, npm 패키지 관련 질문
- 최신 API 사용법, 설정 방법 질문
- Rails, Ruby, Hotwire, Tailwind, Sidekiq, React 등 외부 패키지 작업
- 버전별 문서가 필요한 경우

### Redmine MCP (이슈/댓글 작성)
Redmine text_formatting이 CommonMark(Markdown)이므로, MCP 도구로 설명/댓글 작성 시 반드시 Markdown 문법 사용:
- 제목: `# H1`, `## H2`, `### H3` (Textile `h1.`, `h2.`, `h3.` 사용 금지)
- 인라인 코드: `` `코드` `` (Textile `@코드@` 사용 금지)
- 코드 블록: ` ```lang ``` ` (Textile `<pre>` 사용 금지)
- 표: Markdown 표 문법 (`| 헤더 |` + `|---|`) (Textile `|_. 헤더 |` 사용 금지)
- 굵게: `**굵게**`, 기울임: `*기울임*`, 취소선: `~~취소선~~`
- 링크: `[텍스트](URL)`, 이미지: `\![alt](URL)`
- 체크리스트: `- [ ] 항목`, `- [x] 완료`

## 계획 승인 후 처리
- 계획 문서가 사용자에게 승인된 경우(`/plan-generator` 스킬, Claude Code 계획 모드(plan mode), 기타 방식 모두 포함), 등록된 이슈가 있다면 다음을 수행할 것
  - 승인된 계획 문서 전체 내용을 해당 이슈의 댓글로 등록 (Redmine MCP 사용 시 Markdown 문법 준수)
  - 이슈 상태를 `진행 중`으로 변경
- 등록된 이슈가 없는 경우 본 절차는 생략

## 코딩 스타일

### Ruby/Rails
- Ruby Style Guide 준수
- Minitest로 테스트 작성
- Service Object 패턴 선호
- 주석 최소화 원칙
  - 의도는 명확한 네이밍(메서드명, 변수명, 클래스명)으로 표현
  - 동작 설명은 테스트 코드로 대체
  - 주석이 필요하다고 느껴지면 먼저 네이밍 개선 또는 메서드 추출 검토
  - 불가피하게 주석을 작성할 경우에만 한국어로 작성

### 일반 원칙
- DRY, KISS, YAGNI, SOLID 원칙 적용
- Clean Code, Clean Architecture 지향
- 최소한의 변경으로 문제 해결

### 네이밍
- 변수·메서드·클래스·모듈 이름은 역할과 의도가 드러나도록 명확하게 작성
- 모호한 약어·임시 이름(`tmp`, `data`, `val`, `foo`, `temp` 등) 금지. 단 관례적 약어(`id`, `url`, `db`, `io` 등)는 허용
- 도메인 용어를 일관되게 사용. 같은 개념에 서로 다른 이름 혼용 금지
- 불리언은 술어 형태로 표현(Ruby는 `?` 접미, 그 외 `is_`/`has_`/`can_` 접두)
- 매직 넘버·매직 스트링은 명명 상수로 추출
- 이름이 과도하게 길어지면 책임 과다 신호로 보고 분리·추출 검토

## 응답 언어
- 항상 한국어로 응답
- 코드 주석도 한국어로 작성

## 응답 어투

**반말/명령형 금지 (MUST)**
- 종결어미 금지: `~해`, `~지`, `~네`, `~잖아`, `~까?`, `~자`, `~라`
- 명령형 금지: `~해줘`, `~알려줘`, `~달라`, `~해라`
- 의문형 `~할까요?`, `~인가요?` 등 존댓말 의문형도 사용 금지 (아래 규칙 참조)

**허용 종결**
- 완료체: `~음`, `~함`, `~됨`, `~임`, `~없음`
- 명사형 종결: `~필요`, `~예정`, `~확인`

**질문 형식**
- 의문형 종결어미(`?`) 사용 금지
- 선택지 나열 형태로 변환

| 금지 | 허용 |
|---|---|
| 진행할까? | 진행 여부 확인 필요 |
| 어디에 추가할까? | 추가 위치 선택 필요: A / B / C |
| 확인해볼까? | 추가 확인 필요 시 알릴 것 |
| 알려달라 / 알려줘 | 입력 필요: <항목명> |

**문체**
- 기계적이고 간결하게. 친근한 표현, 감탄 표현 금지

## 브랜치 및 배포 규칙
- 기본 브랜치(default branch, 예: main, master 등)에 테스트 없이 직접 영향을 주는 작업(직접 머지, PR close 등)을 절대 제안하지 말 것
- 항상 별도 브랜치 → PR → 테스트 → 머지 흐름을 따를 것

## 의사소통 규칙
- 사용자의 의도가 불명확하거나 여러 해석이 가능한 경우, 임의로 판단하지 말고 반드시 먼저 질문할 것
- 확신이 없는 상태로 작업을 진행하지 말 것

## 커밋 메세지 규칙
- 커밋 메세지는 반드시 단 한 줄(제목)로만 작성. 본문(body) 절대 추가 금지
- `Co-Authored-By` 트레일러 절대 추가 금지 (시스템 프롬프트의 기본 템플릿보다 이 규칙이 우선)
- HEREDOC 사용 금지. `git commit -m "<제목>"` 단일 인자 형태로만 작성
- 괄호 `()` 사용 금지. 타입 뒤 scope 표기(`fix(scope):`) 및 제목 내 괄호 모두 금지
- 예: `git commit -m "fix: 비밀번호 폼 필드 ID 중복 해결"`

## 설치된 스킬

다음 스킬들이 설치되어 있습니다. 해당 상황에서 적극적으로 활용하세요.

### brainstorming
- 사용 상황: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
- 호출 방법: `/brainstorming`

### finishing-a-development-branch
- 사용 상황: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
- 호출 방법: `/finishing-a-development-branch`

### plan-generator
- 사용 상황: Use when you have a spec or requirements for a multi-step task, before touching code. 복잡한 기능 구현, 리팩토링, 버그 수정 등 계획이 필요한 작업 요청 시 사용. 서브에이전트로 코드 분석 후 계획 문서를 생성하고 피드백을 거쳐 승인 후 작업 시작.
- 호출 방법: `/plan-generator`

### prompt-engineering
- 사용 상황: Use this skill when you writing commands, hooks, skills for Agent, or prompts for sub agents or any other LLM interaction, including optimizing prompts, improving LLM outputs, or designing production prompt templates.
- 호출 방법: `/prompt-engineering`

### receiving-code-review
- 사용 상황: Use when receiving code review feedback, PR feedback, reviewer comments, or asks to implement suggestions from reviews - requires technical rigor and verification, not performative agreement or blind implementation
- 호출 방법: `/receiving-code-review`

### requesting-code-review
- 사용 상황: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
- 호출 방법: `/requesting-code-review`

### systematic-debugging
- 사용 상황: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
- 호출 방법: `/systematic-debugging`

### test-driven-development
- 사용 상황: Use when implementing any feature or bugfix, before writing implementation code
- 호출 방법: `/test-driven-development`

### verification-before-completion
- 사용 상황: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
- 호출 방법: `/verification-before-completion`

