#!/bin/bash

# 전역 Claude 설정 동기화 스크립트 (공유분만 관리)
# 사용법: ./config.sh <backup|deploy>
#   backup : ~/.claude/ 의 공유 파일(shared.md, modules/, hooks/)을 레포로 복사
#   deploy : 레포의 공유 파일을 ~/.claude/ 에 적용하고 settings.json에 공유 설정을 딥머지
#
# 로컬 전용 파일(~/.claude/CLAUDE.md 본문, settings.json의 로컬 키)은 건드리지 않는다.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CLAUDE="$SCRIPT_DIR/home/.claude"
LOCAL_CLAUDE="$HOME/.claude"

IMPORT_LINE="@~/.claude/shared.md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "사용법: ./config.sh <backup|deploy>"
    echo "  backup : ~/.claude/ → 레포 (shared.md, modules/, hooks/)"
    echo "  deploy : 레포 → ~/.claude/ (공유 파일 복사 + settings.json 딥머지)"
}

require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${RED}오류: jq가 필요합니다. (brew install jq)${NC}"
        exit 1
    fi
}

# $1=원본 $2=대상 — 내용이 다를 때만 .bak 백업 후 복사 (권한 유지)
copy_with_bak() {
    local src="$1" dst="$2"
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
        echo -e "  ${GREEN}=${NC} $(basename "$dst") (변경 없음)"
        return
    fi
    if [ -f "$dst" ]; then
        cp -p "$dst" "$dst.bak"
        echo -e "  ${YELLOW}↩${NC} $(basename "$dst") → $(basename "$dst").bak 백업"
    fi
    cp -p "$src" "$dst"
    echo -e "  ${GREEN}✓${NC} $(basename "$dst")"
}

do_backup() {
    echo "[shared.md]"
    if [ -f "$LOCAL_CLAUDE/shared.md" ]; then
        copy_with_bak "$LOCAL_CLAUDE/shared.md" "$REPO_CLAUDE/shared.md"
    else
        echo -e "  ${YELLOW}⚠${NC} ~/.claude/shared.md 없음 — 먼저 deploy로 받아오세요"
    fi

    echo "[modules/]"
    mkdir -p "$REPO_CLAUDE/modules"
    local found=0
    for f in "$LOCAL_CLAUDE"/modules/*.md; do
        [ -f "$f" ] || continue
        found=1
        copy_with_bak "$f" "$REPO_CLAUDE/modules/$(basename "$f")"
    done
    [ "$found" -eq 0 ] && echo "  (없음)"

    echo "[hooks/]"
    mkdir -p "$REPO_CLAUDE/hooks"
    found=0
    for f in "$LOCAL_CLAUDE"/hooks/*.sh; do
        [ -f "$f" ] || continue
        found=1
        copy_with_bak "$f" "$REPO_CLAUDE/hooks/$(basename "$f")"
    done
    [ "$found" -eq 0 ] && echo "  (없음)"

    echo "[settings]"
    echo "  공유 설정은 backup 대상이 아닙니다 — home/.claude/shared-settings.json 을 직접 편집하세요"
}

check_claude_md() {
    local claude_md="$LOCAL_CLAUDE/CLAUDE.md"
    if [ ! -f "$claude_md" ]; then
        printf '# Global Claude Code Instructions\n\n%s\n' "$IMPORT_LINE" > "$claude_md"
        echo -e "  ${GREEN}✓${NC} CLAUDE.md 생성 (import 라인 포함)"
        echo -e "  ${YELLOW}ℹ${NC} 이슈 트래커 모듈을 쓰면 추가: @~/.claude/modules/linear.md 또는 redmine.md"
    elif ! grep -qF "$IMPORT_LINE" "$claude_md"; then
        echo -e "  ${YELLOW}⚠${NC} CLAUDE.md에 import 라인이 없습니다. 아래 라인을 추가하세요:"
        echo "      $IMPORT_LINE"
        echo -e "  ${YELLOW}⚠${NC} 추가 후 shared.md와 중복되는 기존 규칙은 CLAUDE.md에서 제거하세요"
        echo -e "  ${YELLOW}ℹ${NC} 이슈 트래커 모듈을 쓰면 추가: @~/.claude/modules/linear.md 또는 redmine.md"
    else
        echo -e "  ${GREEN}=${NC} CLAUDE.md import 라인 확인됨"
    fi
}

merge_settings() {
    local shared="$REPO_CLAUDE/shared-settings.json"
    local local_settings="$LOCAL_CLAUDE/settings.json"

    if [ ! -f "$shared" ]; then
        echo -e "  ${YELLOW}⚠${NC} 레포에 shared-settings.json 없음, 건너뜀"
        return
    fi
    if ! jq empty "$shared" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} shared-settings.json 파싱 실패 — settings.json을 변경하지 않고 중단합니다"
        exit 1
    fi

    if [ ! -f "$local_settings" ]; then
        cp "$shared" "$local_settings"
        echo -e "  ${GREEN}✓${NC} settings.json 생성 (공유 설정으로 초기화)"
        return
    fi
    if ! jq empty "$local_settings" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} 로컬 settings.json 파싱 실패 — 변경하지 않고 중단합니다"
        exit 1
    fi

    local merged
    merged=$(jq -s '.[0] * .[1]' "$local_settings" "$shared")
    if [ "$(jq -S . "$local_settings")" = "$(printf '%s' "$merged" | jq -S .)" ]; then
        echo -e "  ${GREEN}=${NC} settings.json (변경 없음)"
        return
    fi

    echo -e "  ${YELLOW}ℹ${NC} settings.json 변경 내용:"
    diff <(jq -S . "$local_settings") <(printf '%s' "$merged" | jq -S .) | sed 's/^/      /'
    cp -p "$local_settings" "$local_settings.bak"
    printf '%s\n' "$merged" > "$local_settings"
    echo -e "  ${YELLOW}↩${NC} 기존 settings.json → settings.json.bak 백업"
    echo -e "  ${GREEN}✓${NC} settings.json 머지 완료 (로컬 전용 키 유지)"
}

do_deploy() {
    require_jq
    mkdir -p "$LOCAL_CLAUDE/modules" "$LOCAL_CLAUDE/hooks"

    echo "[shared.md]"
    if [ -f "$REPO_CLAUDE/shared.md" ]; then
        copy_with_bak "$REPO_CLAUDE/shared.md" "$LOCAL_CLAUDE/shared.md"
    else
        echo -e "  ${RED}✗${NC} 레포에 shared.md 없음 — 중단합니다"
        exit 1
    fi

    echo "[modules/]"
    local found=0
    for f in "$REPO_CLAUDE"/modules/*.md; do
        [ -f "$f" ] || continue
        found=1
        copy_with_bak "$f" "$LOCAL_CLAUDE/modules/$(basename "$f")"
    done
    [ "$found" -eq 0 ] && echo "  (없음)"

    echo "[hooks/]"
    found=0
    for f in "$REPO_CLAUDE"/hooks/*.sh; do
        [ -f "$f" ] || continue
        found=1
        copy_with_bak "$f" "$LOCAL_CLAUDE/hooks/$(basename "$f")"
    done
    [ "$found" -eq 0 ] && echo "  (없음)"

    echo "[CLAUDE.md]"
    check_claude_md

    echo "[settings.json]"
    merge_settings
}

ACTION="$1"

echo "=========================================="
echo "  전역 Claude 설정 $ACTION"
echo "=========================================="

case "$ACTION" in
    backup) do_backup ;;
    deploy) do_deploy ;;
    *)
        echo -e "${RED}오류: backup 또는 deploy 를 지정해주세요.${NC}"
        usage
        exit 1
        ;;
esac

echo "------------------------------------------"
echo -e "${GREEN}완료!${NC}"
