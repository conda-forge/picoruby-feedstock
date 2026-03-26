#!/bin/bash

set -exo pipefail

export LD=${CC}
export MRUBY_CONFIG="${SRC_DIR}/build_config/default.rb"

# picoruby's build.rb runs `git log` and `git branch` during configuration,
# but conda build environments unpack from a tarball and have no .git directory.
# Initialize a minimal git repo so those commands do not fail.
mkdir -p "${SRC_DIR}/.git"
git -C "${SRC_DIR}" init
git -C "${SRC_DIR}" config user.email "conda@build.local"
git -C "${SRC_DIR}" config user.name "conda build"
# Stage all files so the commit is non-empty and git log works correctly
git -C "${SRC_DIR}" add -A
git -C "${SRC_DIR}" commit -m "conda build placeholder"

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
