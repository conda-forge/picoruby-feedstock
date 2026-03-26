#!/bin/bash

set -exo pipefail

export LD=${CC}
export MRUBY_CONFIG="${SRC_DIR}/build_config/default.rb"

# picoruby's build.rb runs `git log` and `git branch` during configuration,
# but conda build environments unpack from a tarball and have no .git directory.
# Initialize a minimal git repo so those commands do not fail.
git -C "${SRC_DIR}" init
git -C "${SRC_DIR}" config user.email "conda@build.local"
git -C "${SRC_DIR}" config user.name "conda build"
git -C "${SRC_DIR}" add -A
git -C "${SRC_DIR}" commit -m "conda build placeholder"

# Pre-generate src/version.c from src/version.c.in
# picoruby/build.rb reads this file during Rakefile load (config phase).
TIMESTAMP=$(git -C "${SRC_DIR}" log -1 --format="%ct")
COMMIT_HASH=$(git -C "${SRC_DIR}" log -1 --format="%h")
BRANCH=$(git -C "${SRC_DIR}" branch --show-current)
BUILD_DATE=$(date -u +"%Y-%m-%d")
COMMIT_TIMESTAMP=$(date -u -d "@${TIMESTAMP}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                   date -u -r "${TIMESTAMP}" +"%Y-%m-%dT%H:%M:%SZ")

sed \
  -e "s|@PICORUBY_COMMIT_TIMESTAMP@|${COMMIT_TIMESTAMP}|g" \
  -e "s|@PICORUBY_COMMIT_BRANCH@|${BRANCH}|g" \
  -e "s|@PICORUBY_COMMIT_HASH@|${COMMIT_HASH}|g" \
  -e "s|@PICORUBY_BUILD_DATE@|${BUILD_DATE}|g" \
  "${SRC_DIR}/src/version.c.in" > "${SRC_DIR}/src/version.c"

echo "git log test:"
git -C "${SRC_DIR}" log -1 --format="%ct %h"
git -C "${SRC_DIR}" branch --show-current

# When cross-compiling on Mac, skip tests even if errors occur.
if [[ $(uname) == "Darwin" && (${build_platform} != ${target_platform}) ]]; then
  rake || true
else
  rake
fi

mkdir -p ${PREFIX}/{bin,include,lib}
install -m 755 build/host/bin/* ${PREFIX}/bin
install -m 644 build/host/lib/* ${PREFIX}/lib
cp -r include/* "${PREFIX}/include/"
