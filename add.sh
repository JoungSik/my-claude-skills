#!/bin/bash

# 외부 스킬 저장소 추가 스크립트
# 사용법: ./add.sh <저장소URL> [폴더명]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_URL="$1"
CUSTOM_NAME="$2"

if [ -z "$REPO_URL" ]; then
    echo -e "${RED}오류: 저장소 URL을 입력해주세요.${NC}"
    echo "사용법: ./add.sh <저장소URL> [폴더명]"
    exit 1
fi

# 폴더명 결정 (사용자 지정 또는 저장소 이름에서 추출)
if [ -n "$CUSTOM_NAME" ]; then
    SKILL_NAME="$CUSTOM_NAME"
else
    SKILL_NAME=$(basename "$REPO_URL" .git)
fi

DEST_DIR="$SKILLS_DIR/$SKILL_NAME"

# skills 디렉토리 생성
mkdir -p "$SKILLS_DIR"

# 이미 존재하는지 확인
if [ -d "$DEST_DIR" ]; then
    echo -e "${YELLOW}경고: '$SKILL_NAME' 폴더가 이미 존재합니다.${NC}"
    read -p "덮어쓰시겠습니까? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "취소되었습니다."
        exit 0
    fi
    rm -rf "$DEST_DIR"
fi

echo "=========================================="
echo "  스킬 저장소 추가"
echo "=========================================="
echo "URL: $REPO_URL"
echo "이름: $SKILL_NAME"
echo "------------------------------------------"

# 저장소 클론
echo "저장소 복사 중..."
git clone --depth 1 "$REPO_URL" "$DEST_DIR" 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}오류: 저장소 클론에 실패했습니다.${NC}"
    exit 1
fi

# .git 폴더 삭제 (직접 복사 방식)
rm -rf "$DEST_DIR/.git"

echo "------------------------------------------"
echo -e "${GREEN}추가 완료!${NC}"
echo "위치: $DEST_DIR"
echo ""
echo "설치하려면: ./install.sh $SKILL_NAME"
