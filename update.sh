#!/bin/bash

# 수집한 스킬을 SOURCE.md의 원본 저장소 최신 내용으로 갱신
# 사용법: ./update.sh [--check] [스킬명]
#   --check  변경 여부와 diff만 출력하고 파일은 수정하지 않음

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
CUSTOM_SECTION_HEADER="커스텀 변경사항"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHECK_ONLY=false
TARGET=""
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=true ;;
        *) TARGET="$arg" ;;
    esac
done

CLONE_ROOT=$(mktemp -d) || exit 1
trap 'rm -rf "$CLONE_ROOT"' EXIT

sed_in_place() {
    local file="$1"
    shift
    local tmp_file
    tmp_file=$(mktemp) || return 1
    sed "$@" "$file" > "$tmp_file" && cat "$tmp_file" > "$file"
    rm -f "$tmp_file"
}

# SOURCE.md의 "- **키**: 값" 형식에서 값 추출
read_source_field() {
    local source_md="$1" key="$2"
    grep -E "^- \*\*${key}\*\*:" "$source_md" | head -1 | sed -E 's/^[^:]+:[[:space:]]*//'
}

# 같은 저장소는 한 번만 클론
clone_repo() {
    local repo_url="$1"
    local clone_dir="$CLONE_ROOT/$(echo "$repo_url" | tr -c 'A-Za-z0-9' '_')"
    if [ ! -d "$clone_dir" ]; then
        git clone --quiet --depth 1 "$repo_url" "$clone_dir" 2>/dev/null || return 1
    fi
    echo "$clone_dir"
}

replace_skill_files() {
    local upstream_path="$1" skill_dir="$2"
    find "$skill_dir" -mindepth 1 -maxdepth 1 ! -name SOURCE.md -exec rm -rf {} +
    if [ -d "$upstream_path" ]; then
        cp -Rp "$upstream_path/." "$skill_dir/"
    else
        cp -p "$upstream_path" "$skill_dir/"
    fi
}

update_skill() {
    local skill_dir="${1%/}"
    local skill_name source_md repo_url relative_path clone_dir upstream_path diff_output
    skill_name="$(basename "$skill_dir")"
    source_md="$skill_dir/SOURCE.md"

    if [ ! -f "$source_md" ]; then
        echo -e "${YELLOW}-${NC} $skill_name: SOURCE.md 없음 (로컬 스킬, 건너뜀)"
        return
    fi

    repo_url=$(read_source_field "$source_md" "저장소")
    relative_path=$(read_source_field "$source_md" "경로")
    [ -z "$relative_path" ] && relative_path=$(read_source_field "$source_md" "파일")

    if [ -z "$repo_url" ] || [ -z "$relative_path" ]; then
        echo -e "${RED}✗${NC} $skill_name: SOURCE.md에 저장소·경로 정보 없음"
        return
    fi

    if ! clone_dir=$(clone_repo "$repo_url"); then
        echo -e "${RED}✗${NC} $skill_name: 클론 실패 ($repo_url)"
        return
    fi

    upstream_path="$clone_dir/${relative_path%/}"
    if [ ! -e "$upstream_path" ]; then
        echo -e "${RED}✗${NC} $skill_name: 원본 경로 없음 ($relative_path)"
        return
    fi

    if [ -d "$upstream_path" ]; then
        diff_output=$(diff -ru -x SOURCE.md "$skill_dir" "$upstream_path")
    else
        diff_output=$(diff -u "$skill_dir/$(basename "$upstream_path")" "$upstream_path")
    fi

    if [ -z "$diff_output" ]; then
        echo -e "${GREEN}=${NC} $skill_name: 최신"
        return
    fi

    echo -e "${YELLOW}△${NC} $skill_name: 원본 변경 있음"
    echo "$diff_output" | sed 's/^/    /'

    if $CHECK_ONLY; then
        return
    fi

    if grep -q "$CUSTOM_SECTION_HEADER" "$source_md"; then
        echo -e "${YELLOW}⚠${NC} $skill_name: SOURCE.md에 커스텀 변경사항이 있어 덮어쓰지 않음. 수동 반영 필요"
        return
    fi

    replace_skill_files "$upstream_path" "$skill_dir"
    sed_in_place "$source_md" -E "s/^(- \*\*수집일\*\*:).*/\1 $(date +%Y-%m-%d)/"
    echo -e "${GREEN}✓${NC} $skill_name: 갱신 완료"
}

echo "=========================================="
echo "  스킬 원본 업데이트$($CHECK_ONLY && echo " (확인만)")"
echo "=========================================="

if [ -n "$TARGET" ]; then
    if [ ! -d "$SKILLS_SRC/$TARGET" ]; then
        echo -e "${RED}오류: '$TARGET' 스킬을 찾을 수 없습니다.${NC}"
        exit 1
    fi
    update_skill "$SKILLS_SRC/$TARGET"
else
    for skill_dir in "$SKILLS_SRC"/*/; do
        [ -d "$skill_dir" ] && update_skill "$skill_dir"
    done
fi

echo "------------------------------------------"
if ! $CHECK_ONLY; then
    echo "로컬에 반영하려면: ./install.sh"
fi
