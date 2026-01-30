#!/bin/bash
# test-chromecast.sh - Test Chromecast streaming with subtitles

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
CHROMECAST_IP="${CHROMECAST_IP:-}"
TEST_VIDEO="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== VLC Chromecast Subtitle Test ==="
echo ""

# Check if VLC is built
if [ ! -f "$SCRIPT_DIR/modules/.libs/libwebvtt_plugin.dylib" ]; then
    echo -e "${RED}Error: WebVTT plugin not found. Run 'make' first.${NC}"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/modules/.libs/libmux_webvtt_plugin.dylib" ]; then
    echo -e "${RED}Error: WebVTT muxer plugin not found. Run 'make' first.${NC}"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/modules/.libs/libstream_out_chromecast_plugin.dylib" ]; then
    echo -e "${RED}Error: Chromecast plugin not found. Run 'make' first.${NC}"
    exit 1
fi

echo -e "${GREEN}All required plugins found.${NC}"
echo ""

# Check for Chromecast IP
if [ -z "$CHROMECAST_IP" ]; then
    echo -e "${YELLOW}No Chromecast IP specified.${NC}"
    echo "Usage: CHROMECAST_IP=192.168.1.100 $0 video.mkv"
    echo "   or: $0 video.mkv  (will prompt for IP)"
    echo ""
    read -p "Enter Chromecast IP address: " CHROMECAST_IP
fi

if [ -z "$CHROMECAST_IP" ]; then
    echo -e "${RED}Error: Chromecast IP is required.${NC}"
    exit 1
fi

# Check for test video
if [ -z "$TEST_VIDEO" ]; then
    echo -e "${YELLOW}No test video specified.${NC}"
    read -p "Enter path to video file: " TEST_VIDEO
fi

if [ ! -f "$TEST_VIDEO" ]; then
    echo -e "${RED}Error: Video file not found: $TEST_VIDEO${NC}"
    exit 1
fi

echo ""
echo "Configuration:"
echo "  Chromecast IP: $CHROMECAST_IP"
echo "  Video file: $TEST_VIDEO"
echo ""

# Run VLC with Chromecast
echo "Starting VLC with Chromecast output..."
echo ""

exec "$SCRIPT_DIR/run-vlc.sh" -vvv \
    --sout "#chromecast{ip=$CHROMECAST_IP}" \
    "$TEST_VIDEO"
