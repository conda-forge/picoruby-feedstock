#!/bin/bash

set -exo pipefail

mkdir -p "${SRC_DIR}/.bin"
ln -sf "${CC}" "${SRC_DIR}/.bin/clang"
export PATH="${SRC_DIR}/.bin:${PATH}"
export CC=clang
export LD=${CC}
export MRUBY_CONFIG="${SRC_DIR}/build_config/default.rb"

# When cross-compiling on Mac, skip tests even if errors occur.
if [[ $(uname) == "Darwin" && "${build_platform}" != "${target_platform}" ]]; then
  rake || true
else
  rake
fi

mkdir -p "${PREFIX}/bin" "${PREFIX}/include" "${PREFIX}/lib"

find build/host/bin -maxdepth 1 -type f -exec install -m 755 {} "${PREFIX}/bin/" \;
find build/host/lib -maxdepth 1 -type f -exec install -m 644 {} "${PREFIX}/lib/" \;
cp -r include/* "${PREFIX}/include/"
