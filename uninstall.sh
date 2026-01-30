#!/bin/bash

# 스킬 제거 스크립트
# 사용법: ./uninstall.sh [스킬명]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DEST="$HOME/.claude/skills"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
TARGET="$1"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "  Claude Code 스킬 제거"
echo "=========================================="

# 제거 함수
uninstall_skill() {
    local skill_name="$1"
    local dest_dir="$SKILLS_DEST/$skill_name"

    if [ -d "$dest_dir" ]; then
        rm -rf "$dest_dir"
        echo -e "${YELLOW}✓${NC} 제거: $skill_name"
    else
        echo -e "${YELLOW}⚠${NC} $skill_name: 설치되어 있지 않음"
    fi
}

# CLAUDE.md에서 스킬 섹션 제거
remove_skill_section() {
    if [ ! -f "$CLAUDE_MD" ]; then
        return
    fi

    # "## 설치된 스킬" 섹션 전체 제거
    if grep -q "^## 설치된 스킬" "$CLAUDE_MD"; then
        # 임시 파일 생성
        local tmp_file=$(mktemp)

        # 섹션 제거 (## 설치된 스킬부터 다음 ##까지, 또는 파일 끝까지)
        awk '
            /^## 설치된 스킬$/ { skip=1; next }
            /^## / && skip { skip=0 }
            !skip { print }
        ' "$CLAUDE_MD" > "$tmp_file"

        # 파일 끝의 빈 줄 정리
        sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp_file"

        mv "$tmp_file" "$CLAUDE_MD"
        echo -e "${GREEN}✓${NC} CLAUDE.md에서 스킬 섹션 제거 완료"
    fi
}

# 제거 실행
if [ -n "$TARGET" ]; then
    # 특정 스킬만 제거
    echo "스킬: $TARGET"
    echo "------------------------------------------"
    uninstall_skill "$TARGET"
else
    # 전체 제거 (skills 폴더에 있는 것들만)
    echo "전체 스킬 제거"
    echo "------------------------------------------"
    if [ -d "$SKILLS_SRC" ]; then
        for skill_dir in "$SKILLS_SRC"/*/; do
            [ -d "$skill_dir" ] && uninstall_skill "$(basename "$skill_dir")"
        done
    fi
fi

# 빈 디렉토리 정리
find "$SKILLS_DEST" -type d -empty -delete 2>/dev/null

# CLAUDE.md 정리
remove_skill_section

echo "------------------------------------------"
echo -e "${GREEN}제거 완료!${NC}"
