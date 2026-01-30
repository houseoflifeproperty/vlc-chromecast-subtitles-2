# Chromecast Subtitle Implementation Notes

This document describes how Chromecast subtitle support is implemented in VLC 3.0.22.

## Overview

Chromecast subtitle support requires:
1. **WebVTT Encoder** - Converts VLC's internal subtitle format to WebVTT (ISO 14496-30)
2. **WebVTT Muxer** - Muxes WebVTT cues into a streamable format
3. **Chromecast Module** - Handles SPU streams and sends subtitle tracks to Chromecast

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Input Stream   │────▶│  WebVTT Encoder │────▶│   WebVTT Muxer  │
│  (SRT, ASS...)  │     │   (encvtt.c)    │     │   (muxvtt.c)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   Chromecast    │
                                               │   (cast.cpp)    │
                                               └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │  Chromecast TV  │
                                               │  (WebVTT track) │
                                               └─────────────────┘
```

## WebVTT Encoder (encvtt.c)

### Purpose
Encodes VLC's internal `subpicture_t` subtitle format into WebVTT ISO 14496-30 boxes.

### Key Functions
- `webvtt_OpenEncoder()` - Initialize encoder
- `webvtt_CloseEncoder()` - Cleanup
- `Encode()` - Convert subpicture to WebVTT boxes

### Box Format (ISO 14496-30)
```
vttc box (cue container)
├── payl box (payload - subtitle text)
├── sttg box (settings - positioning)
└── iden box (identifier - optional)

vtte box (empty cue - gap marker)
```

### VLC 3.0.22 Compatibility Fixes
1. **bo_size() macro** - Not defined in VLC 3.0.22's vlc_boxes.h
2. **No ruby text** - `text_segment_ruby_t` is VLC 4.x only
3. **LIFO tag closing** - Tags must close in reverse order (`</i></u></b>`)

## WebVTT Muxer (muxvtt.c)

### Purpose
Muxes encoded WebVTT boxes into a streamable WebVTT file format.

### Key Functions
- `Open()` / `Close()` - Lifecycle
- `Mux()` - Process input blocks
- `OutputTime()` - Format timestamps as `HH:MM:SS.mmm`

### Output Format
```
WEBVTT

00:00:01.000 --> 00:00:04.000
Hello, world!

00:00:05.500 --> 00:00:08.200
This is a subtitle.
```

## Chromecast Module (cast.cpp)

### SPU Stream Detection
```cpp
#define CC_ENABLE_SPU  // Enable subtitle support

// In Add() function:
if (p_fmt->i_cat == SPU_ES) {
    // Handle subtitle stream
    ss_spu_out << "transcode{acodec=0,vcodec=0,scodec=wvtt}:"
}
```

### Subtitle Track in Media Message
The Chromecast receiver expects subtitle tracks in the LOAD message:
```json
{
  "media": {
    "tracks": [{
      "trackId": 1,
      "type": "TEXT",
      "trackContentType": "text/vtt",
      "trackContentId": "http://vlc-host:port/subtitles.vtt"
    }]
  },
  "activeTrackIds": [1]
}
```

## Module Registration

### Encoder (webvtt.c)
```c
#ifdef ENABLE_SOUT
add_submodule()
    set_shortname( "WEBVTT" )
    set_description( N_("WEBVTT subtitles encoder") )
    set_capability( "encoder", 101 )
    set_category( CAT_SOUT )
    set_subcategory( SUBCAT_SOUT_STREAM )
    set_callbacks( webvtt_OpenEncoder, webvtt_CloseEncoder )
#endif
```

### Muxer (mux/Makefile.am)
```makefile
libmux_webvtt_plugin_la_SOURCES = mux/muxvtt.c
mux_LTLIBRARIES += libmux_webvtt_plugin.la
```

## FourCC Codes

| Code | Description |
|------|-------------|
| `wvtt` | WebVTT subtitle codec |
| `vttc` | WebVTT cue box |
| `vtte` | WebVTT empty cue box |
| `payl` | Payload box |
| `sttg` | Settings box |
| `iden` | Identifier box |

## Debugging

Enable verbose logging:
```bash
./vlc -vvv --sout '#chromecast{ip=192.168.1.100}' video.mkv 2>&1 | grep -i "webvtt\|subtitle\|spu"
```

Check encoder is loaded:
```bash
./vlc --list | grep -i webvtt
```
