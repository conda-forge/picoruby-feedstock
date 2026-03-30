#!/bin/bash

set -exo pipefail

mkdir -p "${SRC_DIR}/.bin"
ln -sf "${CC}" "${SRC_DIR}/.bin/clang"
export PATH="${SRC_DIR}/.bin:${PATH}"
export CC=clang
export LD=${CC}
export MRUBY_CONFIG="${SRC_DIR}/build_config/default.rb"

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
