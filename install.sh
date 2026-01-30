#!/bin/bash

# 스킬 설치 스크립트
# 사용법: ./install.sh [스킬명]

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
echo "  Claude Code 스킬 설치"
echo "=========================================="

# skills 디렉토리 확인
if [ ! -d "$SKILLS_SRC" ]; then
    echo -e "${YELLOW}추가된 스킬이 없습니다.${NC}"
    echo "./add.sh <저장소URL> 로 스킬을 먼저 추가해주세요."
    exit 0
fi

# 대상 디렉토리 생성
mkdir -p "$SKILLS_DEST"

# frontmatter에서 description 추출
extract_description() {
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | grep -E "^description:" | sed 's/^description:[[:space:]]*//'
}

# frontmatter에서 name 추출
extract_name() {
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | grep -E "^name:" | sed 's/^name:[[:space:]]*//'
}

# 설치 함수
install_skill_dir() {
    local skill_dir="${1%/}"
    local skill_name="$(basename "$skill_dir")"
    local dest_dir="$SKILLS_DEST/$skill_name"

    # 대상 디렉토리 생성 (기존 것 삭제 후 새로 생성)
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"

    # 전체 내용 복사 (메타 파일 제외)
    # 1. 스킬 .md 파일 복사
    find "$skill_dir" -maxdepth 1 -name "*.md" -type f ! -name "README.md" ! -name "CHANGELOG.md" ! -name "LICENSE.md" ! -name "SOURCE.md" | while read -r file; do
        local filename="$(basename "$file")"
        cp "$file" "$dest_dir/$filename"
        echo -e "${GREEN}✓${NC} $skill_name/$filename"

        # 스킬 정보 추출 및 저장
        local desc=$(extract_description "$file")
        local name=$(extract_name "$file")
        [ -z "$name" ] && name="$skill_name"

        if [ -n "$desc" ]; then
            echo "$name|$desc" >> "$SCRIPT_DIR/.installed_skills.tmp"
        fi
    done

    # 2. scripts 폴더 복사
    if [ -d "$skill_dir/scripts" ]; then
        cp -r "$skill_dir/scripts" "$dest_dir/"
        local script_count=$(find "$skill_dir/scripts" -type f | wc -l | tr -d ' ')
        echo -e "${GREEN}✓${NC} $skill_name/scripts/ (${script_count}개 파일)"
    fi

    # 3. references 폴더 복사
    if [ -d "$skill_dir/references" ]; then
        cp -r "$skill_dir/references" "$dest_dir/"
        local ref_count=$(find "$skill_dir/references" -type f | wc -l | tr -d ' ')
        echo -e "${GREEN}✓${NC} $skill_name/references/ (${ref_count}개 파일)"
    fi

    # 4. assets 폴더 복사
    if [ -d "$skill_dir/assets" ]; then
        cp -r "$skill_dir/assets" "$dest_dir/"
        local asset_count=$(find "$skill_dir/assets" -type f | wc -l | tr -d ' ')
        echo -e "${GREEN}✓${NC} $skill_name/assets/ (${asset_count}개 파일)"
    fi
}

# CLAUDE.md 업데이트 함수
update_claude_md() {
    local tmp_file="$SCRIPT_DIR/.installed_skills.tmp"

    if [ ! -f "$tmp_file" ]; then
        return
    fi

    # CLAUDE.md가 없으면 생성
    if [ ! -f "$CLAUDE_MD" ]; then
        echo "# Global Claude Code Instructions" > "$CLAUDE_MD"
        echo "" >> "$CLAUDE_MD"
    fi

    # 기존 스킬 섹션 제거
    if grep -q "^## 설치된 스킬" "$CLAUDE_MD"; then
        sed -i '' '/^## 설치된 스킬$/,/^## [^설]/{/^## [^설]/!d;}' "$CLAUDE_MD"
        sed -i '' '/^## 설치된 스킬$/d' "$CLAUDE_MD"
    fi

    # 새 스킬 섹션 추가
    echo "" >> "$CLAUDE_MD"
    echo "## 설치된 스킬" >> "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    echo "다음 스킬들이 설치되어 있습니다. 해당 상황에서 적극적으로 활용하세요." >> "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"

    while IFS='|' read -r name desc; do
        echo "### $name" >> "$CLAUDE_MD"
        echo "- 사용 상황: $desc" >> "$CLAUDE_MD"
        echo "- 호출 방법: \`/$name\`" >> "$CLAUDE_MD"
        echo "" >> "$CLAUDE_MD"
    done < "$tmp_file"

    rm -f "$tmp_file"
    echo -e "${GREEN}✓${NC} CLAUDE.md 업데이트 완료"
}

# 임시 파일 초기화
rm -f "$SCRIPT_DIR/.installed_skills.tmp"

# 설치 실행
if [ -n "$TARGET" ]; then
    # 특정 스킬만 설치
    if [ -d "$SKILLS_SRC/$TARGET" ]; then
        echo "스킬: $TARGET"
        echo "------------------------------------------"
        install_skill_dir "$SKILLS_SRC/$TARGET"
    else
        echo -e "${RED}오류: '$TARGET' 스킬을 찾을 수 없습니다.${NC}"
        exit 1
    fi
else
    # 전체 설치
    echo "전체 스킬 설치"
    echo "------------------------------------------"
    for skill_dir in "$SKILLS_SRC"/*/; do
        [ -d "$skill_dir" ] && install_skill_dir "$skill_dir"
    done
fi

# CLAUDE.md 업데이트
update_claude_md

echo "------------------------------------------"
echo -e "${GREEN}설치 완료!${NC}"
echo "스킬 위치: $SKILLS_DEST"
