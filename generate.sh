#!/usr/bin/env bash

# Cleanup
rm -rf flipper
rm -f flipper.tar.gz

# Get latest version published by Meta
REPO="facebook/flipper"
LATEST_TAG=$(curl -L https://github.com/facebook/flipper/releases/latest  | grep "facebook/flipper/releases/tag" -m 1 | sed "s/.*releases\/tag\///;s/\".*//")
TARBALL_URL="https://github.com/facebook/flipper/archive/refs/tags/$LATEST_TAG.tar.gz"

SOURCE_TAR="flipper.tar.gz"
curl -L -o $SOURCE_TAR $TARBALL_URL

mkdir -p flipper
tar -xf $SOURCE_TAR -C flipper --strip-components=1

# Apply patches
pushd flipper
git init && git add . && git commit -m "Original source"


git remote add flipperUpstream https://github.com/facebook/flipper
git fetch flipperUpstream pull/3553/head:universalBuild

git cherry-pick --keep-redundant-commits \
6cc083b860bb156592dfc622174e6f8d780a6b97 \
2216a3f94db296290b855f036c80a6643d20e884 \
1e1cc37c3bff012f6b9f8c376baeb4675f6dfa29 \
b26997af00b3779dc8fc65e889b87312ae21fea5 \
bd477678bc7698b16339aa7f8957f29811cbb0ab \
ed6e15edc8bd4e4c496088d76e46aeea724a4375 

pushd desktop
if grep -Fxq "@electron/universal" package.json
then
    echo "electron/universal is present in the resolutions"
else
    echo "Patching electron/universal in the resolutions"
    resolutions='"resolutions": {'
    electron_resolution='"@electron/universal": "1.3.4",'
    sed -i '' "/$resolutions/ a\\
    $electron_resolution
    " package.json
fi

# To fix some errors shows in CI, suggesting that repository key should be present in package.json
build_info='"homepage":'
repository_info='"repository": "facebook/flipper",'

sed -i '' "/$build_info/ a\\
  $repository_info
" package.json

yarn install
yarn build --mac-dmg
