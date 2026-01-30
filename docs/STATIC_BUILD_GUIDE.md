# VLC 3.0.22 Static Build Guide for macOS (with Chromecast Subtitle Support)

This guide documents how to build VLC 3.0.22 with static linking (no Homebrew dependencies) and Chromecast subtitle support for use with BitLord.

## Prerequisites

- macOS with Xcode Command Line Tools
- Git

## Build Order (MUST follow this sequence)

### 1. Build extras/tools first (in clean environment)

```bash
cd /Users/leiferik/vlc-chromecast-subtitles
env -i HOME="$HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    bash -c 'cd extras/tools && ./bootstrap && make'
```

### 2. Bootstrap contribs for aarch64

```bash
cd contrib
mkdir -p native && cd native
../bootstrap --build=aarch64-apple-darwin$(uname -r | cut -d. -f1)
```

### 3. Skip non-essential packages

```bash
touch .fluid .projectM .sidplay2 .goom
```

### 4. Build contribs with SDK flags

```bash
export SDKROOT=$(xcrun --show-sdk-path)
export CFLAGS="-isysroot $SDKROOT"
export CXXFLAGS="-isysroot $SDKROOT"
export LDFLAGS="-isysroot $SDKROOT"
make -j8
```

### 5. Build Sparkle explicitly

```bash
make .sparkle
```

### 6. Regenerate protobuf files

```bash
cd ../..
PROTOC=$PWD/extras/tools/build/bin/protoc
$PROTOC --version  # Should be 3.1.0
$PROTOC --cpp_out=modules/stream_out/chromecast \
    modules/stream_out/chromecast/chromecast.proto
```

### 7. Bootstrap VLC

```bash
./bootstrap
```

### 8. Configure VLC

```bash
CONTRIB_DIR=$PWD/contrib/aarch64-apple-darwin$(uname -r | cut -d. -f1)

./configure \
    --enable-chromecast \
    --enable-sout \
    --disable-screen \
    --with-contrib=$CONTRIB_DIR \
    CFLAGS="-I$CONTRIB_DIR/include" \
    CXXFLAGS="-I$CONTRIB_DIR/include" \
    LDFLAGS="-L$CONTRIB_DIR/lib -F$CONTRIB_DIR/Frameworks" \
    OBJCFLAGS="-F$CONTRIB_DIR/Frameworks"
```

### 9. Build VLC

```bash
make -j8
```

## Critical Fixes Applied

### WebVTT Encoder (encvtt.c)
- Added `bo_size()` macro (not in VLC 3.0.22 vlc_boxes.h)
- Removed VLC 4.x `p_ruby` code (ruby text not available in 3.0.x)
- Fixed closing tag order to LIFO (`</i>`, `</u>`, `</b>`)

### Encoder Registration
- Capability set to `"encoder"` (not `"spu encoder"`)
- Priority 101
- Wrapped in `#ifdef ENABLE_SOUT`

### Chromecast Subtitle Support
- SPU stream detection with `CC_ENABLE_SPU`
- WebVTT muxer (`muxvtt.c`)
- Subtitle track in Chromecast media messages

## Common Issues

### "C compiler cannot create executables"
Set SDKROOT and -isysroot flags as shown above.

### extras/tools build fails
Use `env -i` for a clean environment.

### Sparkle framework not found
Build explicitly with `make .sparkle` and add `-F$CONTRIB_DIR/Frameworks`.

### CGDisplayCreateImageForRect obsoleted (macOS 15+)
Add `--disable-screen` to configure.

### Protobuf version mismatch
Use extras/tools protoc 3.1.0, not Homebrew version.

## Verification

Check for Homebrew dependencies:
```bash
for plugin in modules/.libs/*.dylib; do
    if otool -L "$plugin" 2>/dev/null | grep -q "/opt/homebrew\|/usr/local"; then
        echo "HOMEBREW DEP: $plugin"
    fi
done
```

Expected result: No output (zero Homebrew dependencies).

## Copying to BitLord

```bash
BITLORD_VLC=/Users/leiferik/BitLordQt/bitlordqt/3rdparty/mac/vlc

# Copy libraries
cp lib/.libs/libvlc.5.dylib $BITLORD_VLC/lib/
cp lib/.libs/libvlccore.9.dylib $BITLORD_VLC/lib/

# Copy plugins
cp modules/.libs/*.dylib $BITLORD_VLC/plugins/
```
