#!/bin/bash

# 스킬 목록 확인 스크립트

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DEST="$HOME/.claude/skills"

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo "  수집된 스킬 목록"
echo "=========================================="

if [ ! -d "$SKILLS_SRC" ] || [ -z "$(ls -A "$SKILLS_SRC" 2>/dev/null)" ]; then
    echo -e "${YELLOW}추가된 스킬이 없습니다.${NC}"
    echo "./add.sh <저장소URL> 로 스킬을 추가해주세요."
    exit 0
fi

for skill_dir in "$SKILLS_SRC"/*/; do
    [ ! -d "$skill_dir" ] && continue

    skill_name="$(basename "$skill_dir")"
    md_count=$(find "$skill_dir" -name "*.md" -type f ! -name "README.md" ! -name "CHANGELOG.md" ! -name "LICENSE.md" ! -name "SOURCE.md" | wc -l | tr -d ' ')

    # 설치 상태 확인
    if [ -d "$SKILLS_DEST/$skill_name" ]; then
        status="${GREEN}[설치됨]${NC}"
    else
        status="${YELLOW}[미설치]${NC}"
    fi

    echo -e "${CYAN}$skill_name${NC} - ${md_count}개 스킬 파일 $status"

    # 스킬 파일 목록
    find "$skill_dir" -name "*.md" -type f ! -name "README.md" ! -name "CHANGELOG.md" ! -name "LICENSE.md" ! -name "SOURCE.md" -print0 2>/dev/null | while IFS= read -r -d '' file; do
        rel_path="${file#$skill_dir/}"
        echo "  └─ $rel_path"
    done
done

echo "=========================================="
