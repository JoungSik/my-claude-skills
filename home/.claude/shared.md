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
- 스킬/커맨드가 모델을 명시한 경우는 그 지정을 따를 것

## 답변 작성 원칙

채팅 답변의 정보 구조는 ASD-STE100(Simplified Technical English)의 원칙을 80% 수준으로 따릅니다. 문장 표현은 fluent-korean 출력 스타일을 따릅니다. 코드, 코드 주석, 커밋 메시지, PR·이슈 본문에는 적용하지 않습니다.

- 결론이나 결과를 첫 문장에 씁니다. 서론, 요청 재진술, 마무리 인사는 쓰지 않습니다.
- 한 문장에는 사실 하나 또는 지시 하나만 담습니다. 문장이 길어지면 조사와 어미를 줄이지 말고 문장을 나눕니다.
- 문장 길이는 60자 안팎을 목표로 합니다. 상한으로 강제하지는 않습니다.
- 행위의 주체를 밝힙니다. (예: "설정이 변경되었습니다" 대신 "deploy가 settings.json을 변경했습니다")
- 한 개념에는 한 용어만 씁니다. 한 답변 안에서 같은 대상을 다른 이름으로 부르지 않습니다.
- 항목이 둘 이상이면 목록으로 씁니다. 절차는 번호 목록으로 쓰고, 항목마다 지시를 하나만 둡니다.
- 비유와 관용구 대신 일반 어휘를 씁니다.

### 어투

**반말/명령형 금지 (MUST)**
- 종결어미 금지: `~해`, `~지`, `~네`, `~잖아`, `~까?`, `~자`, `~라`
- 명령형 금지: `~해줘`, `~알려줘`, `~달라`, `~해라`
- 의문형 `~할까요?`, `~인가요?` 등 존댓말 의문형도 사용 금지 (아래 규칙 참조)

**질문 형식**
- 의문형 종결어미(`?`) 사용 금지
- 선택지 나열 형태로 변환

## 설치된 스킬

다음 스킬들이 설치되어 있습니다. 해당 상황에서 적극적으로 활용하세요.

### prompt-engineering
- 사용 상황: Use this skill when you writing commands, hooks, skills for Agent, or prompts for sub agents or any other LLM interaction, including optimizing prompts, improving LLM outputs, or designing production prompt templates.
- 호출 방법: `/prompt-engineering`

### eli5
- 사용 상황: Explain a topic like I'm a 5 year old. Use when the user types /eli5 <topic> or asks for a dead-simple picture explainer of how something works.
- 호출 방법: `/eli5`
