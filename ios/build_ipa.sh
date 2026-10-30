#!/bin/zsh
# 本地 Mac 编译（有 Mac 时用；没有 Mac 走 GitHub Actions）
# 用法: sh build_ipa.sh            → 产出 NbTrip-unsigned.ipa
set -e
cd "$(dirname "$0")"

command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate

xcodebuild -project NbTrip.xcodeproj \
  -scheme NbTrip -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/NbTrip.xcarchive archive \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""

rm -rf Payload NbTrip-unsigned.ipa
mkdir -p Payload
cp -R build/NbTrip.xcarchive/Products/Applications/NbTrip.app Payload/
zip -qry NbTrip-unsigned.ipa Payload
echo "✅ NbTrip-unsigned.ipa 已生成（用爱思/AltStore 自签安装）"
