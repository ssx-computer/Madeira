#!/bin/bash
# Configure (first time) and build the ARM64EC FEX module (libarm64ecfex.dll,
# shipped as xtajit64.dll). Options mirror the development build's CMakeCache.
set -eu
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$R/toolchains/llvm-mingw-20260421-ucrt-macos-universal/bin:$PATH"
B="$R/FEX/build-arm64ec"
if [ ! -f "$B/CMakeCache.txt" ]; then
    # The mingw toolchain file sets its compilers with plain set() from
    # MINGW_TRIPLET, which overrides command-line -D values and left the
    # triplet empty on CI. The same settings are passed here explicitly
    # instead (see FEX/Data/CMake/toolchain_mingw.cmake for the source of
    # each value) so no toolchain file is needed.
    TC="$R/toolchains/llvm-mingw-20260421-ucrt-macos-universal/bin"
    MINGW_FLAGS_INIT="-static -static-libgcc -static-libstdc++ -Wl,--file-alignment=4096,/mllvm:-align-loops=1"
    # FEX_IOS_HOST_BUILD switches arm64ecfex to the plain -static link rules;
    # without it the -nostdlib path runs, which cannot reconcile EC-mangled
    # CRT symbols on a macOS-host llvm-mingw (see ARM64EC/CMakeLists.txt).
    cmake -S "$R/FEX" -B "$B" -DCMAKE_BUILD_TYPE=Release -DTUNE_CPU=generic -DFEX_IOS_HOST_BUILD=1 \
        -DCMAKE_C_FLAGS="-DFEX_IOS_HOST=1" -DCMAKE_CXX_FLAGS="-DFEX_IOS_HOST=1" \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_SYSTEM_PROCESSOR=arm64ec-w64-mingw32 \
        -DCMAKE_C_COMPILER="$TC/arm64ec-w64-mingw32-clang" \
        -DCMAKE_CXX_COMPILER="$TC/arm64ec-w64-mingw32-clang++" \
        -DCMAKE_ASM_COMPILER="$TC/arm64ec-w64-mingw32-clang" \
        -DCMAKE_RC_COMPILER="$TC/arm64ec-w64-mingw32-windres" \
        -DCMAKE_AR="$TC/arm64ec-w64-mingw32-ar" \
        -DCMAKE_SHARED_LINKER_FLAGS_INIT="$MINGW_FLAGS_INIT" \
        -DCMAKE_EXE_LINKER_FLAGS_INIT="$MINGW_FLAGS_INIT" \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DENABLE_FEX_ALLOCATOR=ON -DENABLE_JEMALLOC_GLIBC_ALLOC=ON -DENABLE_OFFLINE_RUNTIME=ON \
        -DBUILD_FEXCONFIG=ON -DENABLE_CLANG_THUNKS=ON -DENABLE_CCACHE=ON \
        -DBUILD_TESTING=OFF -DBUILD_THUNKS=OFF -DENABLE_ASSERTIONS=OFF
fi
cmake --build "$B" --target arm64ecfex
cp "$B/Bin/libarm64ecfex.dll" "$R/app/Madeira/arm64ec-windows/xtajit64.dll" && ls -l "$R/app/Madeira/arm64ec-windows/xtajit64.dll"
