#!/bin/bash

set -e

# cleanup
rm -rf .build/ build/

# build for macOS
echo ""
echo "----------------------------------------"
echo "Building for macOS..."
swift build --arch arm64 --arch x86_64 -c release
mkdir -p "build/macOS"
rsync -ar ".build/apple/Products/Release/higitus" "build/macOS"
tar -C build/macOS -czf build/macOS.tar.gz .

# build for linux
if ! command -v docker &> /dev/null; then
    echo "Couldn't build for linux, docker isn't available"
    exit -1
fi

BUILD_CMD="swift build -c release -Xswiftc -O -Xswiftc -static-stdlib -Xlinker -s"

echo ""
echo "----------------------------------------"
echo "Building for Linux ARM64..."
docker container rm -f higitus-linux > /dev/null 2>&1 || true
mkdir -p "build/linux-arm64"
docker run -it --name higitus-linux --platform linux/arm64/v8 -v $(pwd):/higitus swift:latest \
    /bin/bash -c "cd higitus && $BUILD_CMD && BIN=\$($BUILD_CMD --show-bin-path) && cp \$BIN/higitus /higitus/build/linux-arm64/higitus"
tar -C build/linux-arm64 -czf build/linux-arm64.tar.gz .

echo ""
echo "----------------------------------------"
echo "Building for Linux x64..."
docker container rm -f higitus-linux > /dev/null 2>&1 || true
mkdir -p "build/linux-amd64"
docker run -it --name higitus-linux --platform linux/amd64 -v $(pwd):/higitus swift:latest \
    /bin/bash -c "cd higitus && $BUILD_CMD && BIN=\$($BUILD_CMD --show-bin-path) && cp \$BIN/higitus /higitus/build/linux-amd64/higitus"
tar -C build/linux-amd64 -czf build/linux-amd64.tar.gz .

echo "All good!"
