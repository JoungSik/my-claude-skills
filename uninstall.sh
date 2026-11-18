#!/bin/bash

# 스킬 제거 스크립트
# 사용법: ./uninstall.sh [스킬명]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DEST="$HOME/.claude/skills"
SHARED_MD="$HOME/.claude/shared.md"
INSTALLED_MANIFEST="$SKILLS_DEST/.my-claude-skills-installed"
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

    if [ -f "$INSTALLED_MANIFEST" ]; then
        grep -vxF "$skill_name" "$INSTALLED_MANIFEST" > "$INSTALLED_MANIFEST.tmp"
        mv "$INSTALLED_MANIFEST.tmp" "$INSTALLED_MANIFEST"
    fi
}

# BSD/GNU sed의 -i 문법 차이를 피하기 위해 임시 파일 경유로 수정
sed_in_place() {
    local file="$1"
    shift
    local tmp_file
    tmp_file=$(mktemp) || return 1
    sed "$@" "$file" > "$tmp_file" && cat "$tmp_file" > "$file"
    rm -f "$tmp_file"
}

trim_trailing_blank_lines() {
    sed_in_place "$1" -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

# shared.md에서 단일 스킬 항목 제거
remove_single_skill_entry() {
    local skill_name="$1"

    if [ ! -f "$SHARED_MD" ]; then
        return
    fi

    if grep -q "^### ${skill_name}$" "$SHARED_MD"; then
        # ### skill-name 부터 다음 빈 줄까지 제거
        sed_in_place "$SHARED_MD" "/^### ${skill_name}$/,/^$/d"
        trim_trailing_blank_lines "$SHARED_MD"
        echo -e "${GREEN}✓${NC} shared.md에서 '$skill_name' 항목 제거 완료"
    fi
}

# shared.md에서 "## 설치된 스킬" 섹션 전체 제거
remove_skill_section() {
    if [ ! -f "$SHARED_MD" ]; then
        return
    fi

    # "## 설치된 스킬" 섹션 전체 제거
    if grep -q "^## 설치된 스킬" "$SHARED_MD"; then
        # 임시 파일 생성
        local tmp_file=$(mktemp)

        # 섹션 제거 (## 설치된 스킬부터 다음 ##까지, 또는 파일 끝까지)
        awk '
            /^## 설치된 스킬$/ { skip=1; next }
            /^## / && skip { skip=0 }
            !skip { print }
        ' "$SHARED_MD" > "$tmp_file"

        # 권한·심볼릭 링크 유지를 위해 mv 대신 내용만 덮어씀
        cat "$tmp_file" > "$SHARED_MD"
        rm -f "$tmp_file"
        trim_trailing_blank_lines "$SHARED_MD"
        echo -e "${GREEN}✓${NC} shared.md에서 스킬 섹션 제거 완료"
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
find "$SKILLS_DEST" -mindepth 1 -maxdepth 1 -type d -empty -delete 2>/dev/null

# shared.md 정리
if [ -n "$TARGET" ]; then
    remove_single_skill_entry "$TARGET"
else
    remove_skill_section
fi

echo "------------------------------------------"
echo -e "${GREEN}제거 완료!${NC}"
