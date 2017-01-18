#! /bin/bash

set -o xtrace
set -eu

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -n "${TEAMCITY_VERSION:-}" ]; then
  # install dependencies
  $ROOT/prebuild.sh
fi


(
  cd "$ROOT/electron"
  npm install
)

(
  cd "$ROOT/lbry"
  git fetch
  git reset --hard origin/master
  git cherry-pick bd75e88ebebb67897c62a1ee1d3228fd269677dc
  pip install -r requirements.txt
  pip install .
  git reset --hard origin/master
)

(
  cd "$ROOT/lbrynet"
  pyinstaller lbry.py -y --windowed --onefile --icon="$ROOT/lbry/packaging/osx/lbry-osx-app/app.icns"
)

(
  cd "$ROOT/lbry-web-ui"
  git fetch
  git reset --hard origin/master
  git cherry-pick 06224b1d2cf4bf1f63d95031502260dd9c3ec5c1
  npm install
  node_modules/.bin/node-sass --output dist/css --sourcemap=none scss/
  node_modules/.bin/webpack
  git reset --hard origin/master
)

cp -R "$ROOT/lbry-web-ui/dist" "$ROOT/electron/"

mv "$ROOT/lbrynet/dist/lbry" "$ROOT/electron/dist"

if [ -n "${TEAMCITY_VERSION:-}" ]; then
  electron-packager --electron-version=1.4.14 --overwrite "$ROOT/electron" LBRY

  (
    cd "$ROOT"
    if [ "$(uname)" == "Darwin" ]; then
      OS="osx"
      PLATFORM="darwin"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
      OS="linux"
      PLATFORM="linux"
    else
      OS="unknown"
    fi

    tar cvzf "lbry-${OS}.tgz" "LBRY-${PLATFORM}-x64/"
  )

  echo 'Build and packaging complete.'
else
  echo 'Build complete. Run `electron electron` to launch the app'
fi