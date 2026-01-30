# VLC 3.0.22 Build Guide

Quick build guide for VLC 3.0.22 with Chromecast subtitle support.

## Quick Start

```bash
cd /Users/leiferik/vlc-chromecast-subtitles

# Bootstrap
./bootstrap

# Configure (with Chromecast and subtitles)
./configure --enable-chromecast --enable-sout --disable-screen

# Build
make -j8
```

## With Static Linking (No Homebrew Dependencies)

See [STATIC_BUILD_GUIDE.md](STATIC_BUILD_GUIDE.md) for full instructions.

## Key Configure Options

| Option | Description |
|--------|-------------|
| `--enable-chromecast` | Enable Chromecast support |
| `--enable-sout` | Enable stream output (required for encoder) |
| `--disable-screen` | Disable screen capture (fixes macOS 15+ build) |

## Files Modified for Chromecast Subtitles

### WebVTT Encoder
- `modules/codec/webvtt/encvtt.c` - Encoder implementation
- `modules/codec/webvtt/webvtt.h` - Encoder declarations
- `modules/codec/webvtt/webvtt.c` - Encoder module registration
- `modules/codec/Makefile.am` - Include encvtt.c

### WebVTT Muxer
- `modules/mux/muxvtt.c` - Muxer implementation
- `modules/mux/Makefile.am` - Include muxvtt.c

### Chromecast Module
- `modules/stream_out/chromecast/cast.cpp` - SPU stream handling
- `modules/stream_out/chromecast/chromecast.h` - Subtitle declarations
- `modules/stream_out/chromecast/chromecast_communication.cpp` - WebVTT track
- `modules/stream_out/chromecast/chromecast_ctrl.cpp` - Subtitle control
- `modules/stream_out/chromecast/chromecast_demux.cpp` - Subtitle demux

### Core
- `include/vlc_boxes.h` - bo_size() function

## Testing

```bash
# Run VLC with verbose output
./vlc -vvv --sout '#chromecast{ip=<CHROMECAST_IP>}' video.mp4

# Test with subtitles
./vlc -vvv --sout '#chromecast{ip=<CHROMECAST_IP>}' video.mkv
```

## Troubleshooting

### Encoder not found
Ensure `--enable-sout` was passed to configure.

### Subtitles not showing on Chromecast
Check that:
1. WebVTT encoder plugin is built (`libwebvtt_plugin.dylib`)
2. WebVTT muxer plugin is built (`libmux_webvtt_plugin.dylib`)
3. Chromecast plugin is built (`libstream_out_chromecast_plugin.dylib`)
