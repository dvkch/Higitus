#!/bin/bash
set -e

TARGET="${1:-all}"

usage() {
    echo "Usage: $0 [macos|linux-arm64|linux-amd64|all]"
    exit 1
}

case "$TARGET" in
    macos|linux-arm64|linux-amd64|all) ;;
    *) usage ;;
esac

mkdir -p build/

SWIFT_IMAGE="swift:6.4.0"
SDK_URL="https://download.swift.org/swift-6.4.0-release/static-sdk/swift-6.4.0-RELEASE/swift-6.4.0-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz"
SDK_CHECKSUM="47d2fd89eebfdf9eb4d536b6710414297f755c17926cdebc4742c08982b40a9e"
LINUX_CONTAINER="higitus-linux-build"

build_macos() {
    echo ""
    echo "Building for macOS (universal)..."
    swift build --arch arm64 --arch x86_64 -c release -Xswiftc -O
    rm -rf "build/macOS"
    mkdir -p "build/macOS"
    cp ".build/apple/Products/Release/higitus" "build/macOS/"
}

ensure_linux_container() {
    if docker container inspect "$LINUX_CONTAINER" &> /dev/null; then
        docker start "$LINUX_CONTAINER" > /dev/null
        return
    fi

    echo "Provisioning $LINUX_CONTAINER (installing Swift static SDK, first run only)..."
    docker run -d --name "$LINUX_CONTAINER" --platform linux/arm64/v8 -v "$(pwd):/sources" "$SWIFT_IMAGE" sleep infinity

    # swift sdk install sometimes crashes on exit after a successful install (a known
    # swift-corelibs-foundation URLSession bug) -- so check the actual result instead
    # of trusting this command's exit code.
    docker exec "$LINUX_CONTAINER" swift sdk install "$SDK_URL" --checksum "$SDK_CHECKSUM" || true
    if docker exec "$LINUX_CONTAINER" swift sdk list 2>/dev/null | grep -qi "No Swift SDKs"; then
        echo "SDK install actually failed (not just the known exit-crash) -- aborting."
        exit 1
    fi
}

# arch_name: "arm64" | "amd64" (output folder name) ; triple: --swift-sdk target.
build_linux() {
    local arch_name="$1"
    local triple="$2"

    if ! command -v docker &> /dev/null; then
        echo "Couldn't build for linux, docker isn't available"
        exit 1
    fi

    echo ""
    echo "Building for Linux $arch_name (cross-compiled)..."
    ensure_linux_container

    local flags="-c release --swift-sdk $triple -Xswiftc -O -Xlinker -s"
    docker exec "$LINUX_CONTAINER" /bin/bash -c "cd sources && swift build $flags"

    local bin_path
    bin_path=$(docker exec "$LINUX_CONTAINER" /bin/bash -c "cd sources && swift build $flags --show-bin-path")

    rm -rf "build/linux-$arch_name"
    mkdir -p "build/linux-$arch_name"
    cp "${bin_path/\/sources/.}/higitus" "build/linux-$arch_name/"
}

case "$TARGET" in
    macos)        build_macos ;;
    linux-arm64)  build_linux "arm64" "aarch64-swift-linux-musl" ;;
    linux-amd64)  build_linux "amd64" "x86_64-swift-linux-musl" ;;
    all)
        build_macos
        build_linux "arm64" "aarch64-swift-linux-musl"
        build_linux "amd64" "x86_64-swift-linux-musl"
        ;;
esac

docker stop "$LINUX_CONTAINER" > /dev/null 2>&1 || true

echo ""
echo "Archiving"
find build/ -maxdepth 1 -mindepth 1 -type d -exec zip -r {}.zip {} \;
echo "All good!"
