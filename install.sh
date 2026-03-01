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

# 파일 시작의 frontmatter만 추출 (본문 내 --- 무시)
extract_frontmatter() {
    local file="$1"
    # 1행이 ---인 경우에만 두 번째 ---까지 추출
    awk 'NR==1 && /^---$/ { found=1; next } found && /^---$/ { exit } found { print }' "$file"
}

# frontmatter에서 description 추출 (YAML 멀티라인 지원)
extract_description() {
    local file="$1"
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    local first_line
    first_line=$(echo "$frontmatter" | grep -E "^description:" | head -1 | sed 's/^description:[[:space:]]*//')

    if [ "$first_line" = "|" ] || [ "$first_line" = ">" ]; then
        # 멀티라인: description 다음 줄부터 들여쓰기된 줄들을 합침
        echo "$frontmatter" | sed -n '/^description:/,/^[^ ]/p' | tail -n +2 | grep -E "^  " | sed 's/^  //' | tr '\n' ' ' | sed 's/[[:space:]]*$//'
    else
        echo "$first_line"
    fi
}

# frontmatter에서 name 추출
extract_name() {
    local file="$1"
    extract_frontmatter "$file" | grep -E "^name:" | head -1 | sed 's/^name:[[:space:]]*//'
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
    done

    # 스킬 정보 추출 (SKILL.md에서만)
    if [ -f "$skill_dir/SKILL.md" ]; then
        local desc=$(extract_description "$skill_dir/SKILL.md")
        local name=$(extract_name "$skill_dir/SKILL.md")
        [ -z "$name" ] && name="$skill_name"

        if [ -n "$desc" ]; then
            printf '%s\t%s\n' "$name" "$desc" >> "$SCRIPT_DIR/.installed_skills.tmp"
        fi
    fi

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

    if [ -n "$TARGET" ]; then
        # 단일 스킬 설치: 해당 항목만 업데이트
        while IFS=$'\t' read -r name desc; do
            # 섹션이 없으면 새로 생성
            if ! grep -q "^## 설치된 스킬" "$CLAUDE_MD"; then
                echo "" >> "$CLAUDE_MD"
                echo "## 설치된 스킬" >> "$CLAUDE_MD"
                echo "" >> "$CLAUDE_MD"
                echo "다음 스킬들이 설치되어 있습니다. 해당 상황에서 적극적으로 활용하세요." >> "$CLAUDE_MD"
                echo "" >> "$CLAUDE_MD"
            fi

            # 기존 항목 제거 (있으면): ### name 부터 다음 빈 줄까지
            if grep -q "^### ${name}$" "$CLAUDE_MD"; then
                sed -i '' "/^### ${name}$/,/^$/d" "$CLAUDE_MD"
            fi

            # 파일 끝에 새 항목 추가
            echo "### $name" >> "$CLAUDE_MD"
            echo "- 사용 상황: $desc" >> "$CLAUDE_MD"
            echo "- 호출 방법: \`/$name\`" >> "$CLAUDE_MD"
            echo "" >> "$CLAUDE_MD"
        done < "$tmp_file"
    else
        # 전체 설치: 기존 섹션 제거 후 재생성
        if grep -q "^## 설치된 스킬" "$CLAUDE_MD"; then
            sed -i '' '/^## 설치된 스킬$/,$d' "$CLAUDE_MD"
            # 파일 끝 연속 빈 줄 제거
            sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$CLAUDE_MD"
        fi

        echo "" >> "$CLAUDE_MD"
        echo "## 설치된 스킬" >> "$CLAUDE_MD"
        echo "" >> "$CLAUDE_MD"
        echo "다음 스킬들이 설치되어 있습니다. 해당 상황에서 적극적으로 활용하세요." >> "$CLAUDE_MD"
        echo "" >> "$CLAUDE_MD"

        while IFS=$'\t' read -r name desc; do
            echo "### $name" >> "$CLAUDE_MD"
            echo "- 사용 상황: $desc" >> "$CLAUDE_MD"
            echo "- 호출 방법: \`/$name\`" >> "$CLAUDE_MD"
            echo "" >> "$CLAUDE_MD"
        done < "$tmp_file"
    fi

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

    # 소스에 없는 기존 스킬 제거
    if [ -d "$SKILLS_DEST" ]; then
        for dest_skill_dir in "$SKILLS_DEST"/*/; do
            [ ! -d "$dest_skill_dir" ] && continue
            local_name="$(basename "$dest_skill_dir")"
            if [ ! -d "$SKILLS_SRC/$local_name" ]; then
                rm -rf "$dest_skill_dir"
                echo -e "${YELLOW}✗${NC} $local_name (소스에 없어 제거됨)"
            fi
        done
    fi

    for skill_dir in "$SKILLS_SRC"/*/; do
        [ -d "$skill_dir" ] && install_skill_dir "$skill_dir"
    done
fi

# CLAUDE.md 업데이트
update_claude_md

echo "------------------------------------------"
echo -e "${GREEN}설치 완료!${NC}"
echo "스킬 위치: $SKILLS_DEST"
