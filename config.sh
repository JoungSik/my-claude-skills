#!/bin/bash

# 전역 Claude 설정 동기화 스크립트
# 사용법: ./config.sh <backup|deploy>
#   backup : ~/.claude/ 의 설정을 레포로 복사 (로컬 → 레포)
#   deploy : 레포의 설정을 ~/.claude/ 로 복사 (레포 → 로컬)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$SCRIPT_DIR/home/.claude"
CLAUDE_DIR="$HOME/.claude"

# 관리 대상 파일 (settings.local.json은 머신 한정이라 제외)
FILES=("CLAUDE.md" "settings.json")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ACTION="$1"

usage() {
    echo "사용법: ./config.sh <backup|deploy>"
    echo "  backup : ~/.claude/ → 레포 (로컬 설정을 레포에 반영)"
    echo "  deploy : 레포 → ~/.claude/ (레포 설정을 이 머신에 적용)"
}

if [ "$ACTION" != "backup" ] && [ "$ACTION" != "deploy" ]; then
    echo -e "${RED}오류: backup 또는 deploy 를 지정해주세요.${NC}"
    usage
    exit 1
fi

echo "=========================================="
echo "  전역 Claude 설정 $ACTION"
echo "=========================================="

if [ "$ACTION" = "backup" ]; then
    mkdir -p "$CONFIG_SRC"
    for f in "${FILES[@]}"; do
        if [ -f "$CLAUDE_DIR/$f" ]; then
            cp "$CLAUDE_DIR/$f" "$CONFIG_SRC/$f"
            echo -e "${GREEN}✓${NC} $f (~/.claude → 레포)"
        else
            echo -e "${YELLOW}⚠${NC} $f: ~/.claude 에 없음, 건너뜀"
        fi
    done
else
    mkdir -p "$CLAUDE_DIR"
    for f in "${FILES[@]}"; do
        if [ -f "$CONFIG_SRC/$f" ]; then
            if [ -f "$CLAUDE_DIR/$f" ]; then
                cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak"
                echo -e "${YELLOW}↩${NC} 기존 $f → $f.bak 백업"
            fi
            cp "$CONFIG_SRC/$f" "$CLAUDE_DIR/$f"
            echo -e "${GREEN}✓${NC} $f (레포 → ~/.claude)"
        else
            echo -e "${YELLOW}⚠${NC} $f: 레포에 없음, 건너뜀"
        fi
    done
fi

echo "------------------------------------------"
echo -e "${GREEN}완료!${NC}"
