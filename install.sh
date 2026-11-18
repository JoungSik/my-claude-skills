#!/bin/bash

# 스킬 설치 스크립트
# 사용법: ./install.sh [스킬명]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DEST="$HOME/.claude/skills"
SHARED_MD="$HOME/.claude/shared.md"
INSTALLED_MANIFEST="$SKILLS_DEST/.my-claude-skills-installed"
OUTPUT_STYLES_SRC="$SCRIPT_DIR/output-styles"
OUTPUT_STYLES_DEST="$HOME/.claude/output-styles"
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

    # 메타 파일을 제외한 전체 내용 복사 (스킬 문서가 참조하는 스크립트·예제 포함)
    find "$skill_dir" -mindepth 1 -maxdepth 1 ! -name "README.md" ! -name "CHANGELOG.md" ! -name "LICENSE.md" ! -name "SOURCE.md" ! -name ".git" | while read -r entry; do
        local entry_name="$(basename "$entry")"
        cp -Rp "$entry" "$dest_dir/$entry_name"
        if [ -d "$entry" ]; then
            local file_count=$(find "$entry" -type f | wc -l | tr -d ' ')
            echo -e "${GREEN}✓${NC} $skill_name/$entry_name/ (${file_count}개 파일)"
        else
            echo -e "${GREEN}✓${NC} $skill_name/$entry_name"
        fi
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

    record_installed "$skill_name"
}

# output-style은 디렉토리 없이 ~/.claude/output-styles/ 에 .md 파일로 설치
install_output_style_dir() {
    local style_dir="${1%/}"
    local style_name="$(basename "$style_dir")"

    mkdir -p "$OUTPUT_STYLES_DEST"
    find "$style_dir" -mindepth 1 -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "CHANGELOG.md" ! -name "LICENSE.md" ! -name "SOURCE.md" | while read -r style_file; do
        cp -p "$style_file" "$OUTPUT_STYLES_DEST/"
        echo -e "${GREEN}✓${NC} output-style $style_name/$(basename "$style_file")"
    done
}

# 이 레포가 설치한 스킬만 매니페스트에 기록 (외부 동기화 스킬 보호용)
record_installed() {
    local skill_name="$1"
    touch "$INSTALLED_MANIFEST"
    grep -qxF "$skill_name" "$INSTALLED_MANIFEST" || echo "$skill_name" >> "$INSTALLED_MANIFEST"
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
    sed_in_place "$SHARED_MD" -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

append_skill_section_header() {
    printf '\n## 설치된 스킬\n\n다음 스킬들이 설치되어 있습니다. 해당 상황에서 적극적으로 활용하세요.\n' >> "$SHARED_MD"
}

# 항목 앞에 빈 줄을 두어 파일 끝에 빈 줄이 남지 않게 함
append_skill_entry() {
    local name="$1" desc="$2"
    printf '\n### %s\n- 사용 상황: %s\n- 호출 방법: `/%s`\n' "$name" "$desc" "$name" >> "$SHARED_MD"
}

# shared.md 업데이트 함수
update_shared_md() {
    local tmp_file="$SCRIPT_DIR/.installed_skills.tmp"

    if [ ! -f "$tmp_file" ]; then
        return
    fi

    if [ ! -f "$SHARED_MD" ]; then
        rm -f "$tmp_file"
        echo -e "${YELLOW}⚠${NC} ~/.claude/shared.md 없음 — 스킬 목록 갱신 건너뜀 (./config.sh deploy 로 먼저 받아오세요)"
        return
    fi

    if [ -n "$TARGET" ]; then
        # 단일 스킬 설치: 해당 항목만 업데이트
        while IFS=$'\t' read -r name desc; do
            if ! grep -q "^## 설치된 스킬" "$SHARED_MD"; then
                append_skill_section_header
            fi

            # 기존 항목 제거 (있으면): ### name 부터 다음 빈 줄까지
            if grep -q "^### ${name}$" "$SHARED_MD"; then
                sed_in_place "$SHARED_MD" "/^### ${name}$/,/^$/d"
                trim_trailing_blank_lines
            fi

            append_skill_entry "$name" "$desc"
        done < "$tmp_file"
    else
        # 전체 설치: 기존 섹션 제거 후 재생성
        if grep -q "^## 설치된 스킬" "$SHARED_MD"; then
            sed_in_place "$SHARED_MD" '/^## 설치된 스킬$/,$d'
            trim_trailing_blank_lines
        fi

        append_skill_section_header
        while IFS=$'\t' read -r name desc; do
            append_skill_entry "$name" "$desc"
        done < "$tmp_file"
    fi

    rm -f "$tmp_file"
    echo -e "${GREEN}✓${NC} shared.md 업데이트 완료"
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
    elif [ -d "$OUTPUT_STYLES_SRC/$TARGET" ]; then
        echo "output-style: $TARGET"
        echo "------------------------------------------"
        install_output_style_dir "$OUTPUT_STYLES_SRC/$TARGET"
    else
        echo -e "${RED}오류: '$TARGET' 스킬을 찾을 수 없습니다.${NC}"
        exit 1
    fi
else
    # 전체 설치
    echo "전체 스킬 설치"
    echo "------------------------------------------"

    # 이 레포가 설치했지만 소스에서 사라진 스킬만 제거 (매니페스트 밖의 스킬은 보존)
    if [ -f "$INSTALLED_MANIFEST" ]; then
        while read -r installed_name; do
            [ -z "$installed_name" ] && continue
            if [ ! -d "$SKILLS_SRC/$installed_name" ] && [ -d "$SKILLS_DEST/$installed_name" ]; then
                rm -rf "$SKILLS_DEST/$installed_name"
                echo -e "${YELLOW}✗${NC} $installed_name (소스에 없어 제거됨)"
            fi
        done < "$INSTALLED_MANIFEST"
        rm -f "$INSTALLED_MANIFEST"
    fi

    for skill_dir in "$SKILLS_SRC"/*/; do
        [ -d "$skill_dir" ] && install_skill_dir "$skill_dir"
    done

    for style_dir in "$OUTPUT_STYLES_SRC"/*/; do
        [ -d "$style_dir" ] && install_output_style_dir "$style_dir"
    done
fi

# shared.md 업데이트
update_shared_md

echo "------------------------------------------"
echo -e "${GREEN}설치 완료!${NC}"
echo "스킬 위치: $SKILLS_DEST"
