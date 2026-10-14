#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: build.sh output.exe Debug|Release" >&2
    exit 1
fi
case "$2" in
    Debug) assertion_flags="" ;;
    Release) assertion_flags="-DNDEBUG" ;;
    *) echo "Unsupported build configuration: $2" >&2; exit 1 ;;
esac

case "$(uname -m)" in
    arm64) brew_bin=/opt/homebrew/bin/brew ;;
    x86_64) brew_bin=/usr/local/bin/brew ;;
    *) echo "Steam web helper requires a macOS Homebrew toolchain." >&2; exit 1 ;;
esac
if [ ! -x "$brew_bin" ]; then
    echo "Install Homebrew and mingw-w64 to build the Steam web helper." >&2
    exit 1
fi
mingw_root=$("$brew_bin" --prefix mingw-w64)
gcc_bin="$mingw_root/bin/x86_64-w64-mingw32-gcc"
if [ ! -x "$gcc_bin" ]; then
    echo "Run brew install mingw-w64 to build the Steam web helper." >&2
    exit 1
fi
gcc_lib=$(dirname "$("$gcc_bin" -print-libgcc-file-name)")
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "$(dirname -- "$1")"

"$(xcrun --find clang)" --target=x86_64-w64-windows-gnu \
    --sysroot="$mingw_root/toolchain-x86_64/x86_64-w64-mingw32" \
    --ld-path="$mingw_root/bin/x86_64-w64-mingw32-ld" \
    -L"$gcc_lib" -municode -mwindows -static -O2 -Wall -Wextra -Wpedantic \
    $assertion_flags "$source_dir/steamwebhelper.c" -o "$1"

# A PE overlay identifies every Mythic wrapper revision so an app update cannot back up its own wrapper as Valve's helper.
# Keep this marker in sync with Wine.SteamWebHelper.ownershipMarker.
printf 'MythicSteamWebHelperWrapper:v1' >> "$1"
cp "$source_dir/LICENSE.txt" "$(dirname -- "$1")/MythicSteamWebHelper-LICENSE.txt"
