# 공통 지침 (모든 머신 공유)

## 언어

- 항상 한국어로 응답할 것. recap, 요약, 커밋 메시지 등 모든 출력을 한국어로 작성할 것.

## Git 필수 규칙

- **`git push --force` 및 `git push --force-with-lease` 절대 금지**. force push는 PR 이력을 복구 불가능하게 만든다. amend 대신 새 커밋을 생성하고, 필요하면 PR에서 squash merge를 사용할 것.
- 코드 수정, 커밋, 푸시는 반드시 사용자 승인 후 진행할 것.
- **커밋 메시지는 한 줄로 작성할 것**. 제목만 사용하고 본문(body)은 작성하지 않음. 변경 내용을 한 줄 제목에 간결하게 표현할 것.

## MCP 자동 호출 규칙

### Context7 (외부 라이브러리 문서)
다음 상황에서 항상 context7 MCP를 사용할 것:
- 라이브러리, 프레임워크, gem, npm 패키지 관련 질문
- 최신 API 사용법, 설정 방법 질문
- 버전별 문서가 필요한 경우

## 서브에이전트 모델 선택

Agent(서브에이전트) 호출 시 작업 난이도에 따라 model을 지정할 것:

- 단순 탐색/검색/조사(코드 검색, 파일 위치 파악, 문서·웹 조사 등)는 `model: haiku` 지정
- 중간 난이도 분석은 `model: sonnet` 지정
- 계획 수립, 코드 리뷰, 구현 등 무거운 추론 작업은 model을 지정하지 않고 메인 모델을 상속
- 스킬/커맨드가 모델을 명시한 경우(예: plan-generator의 opus)는 그 지정을 따를 것

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
