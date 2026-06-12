# Linear MCP 규칙 (Linear 사용 머신 전용)

## 계획 승인 후 처리
- 계획 문서가 사용자에게 승인된 경우(`/plan-generator` 스킬, Claude Code 계획 모드(plan mode), 기타 방식 모두 포함), 연결된 Linear 이슈가 있다면 다음을 수행할 것
  - 승인된 계획 문서 전체 내용을 해당 이슈의 댓글로 등록 (`save_comment`)
  - 이슈 상태를 `In Progress`로 변경 (`save_issue`)
- 연결된 이슈가 없는 경우 본 절차는 생략
