# Demo video

The 1:59.8 product demo and what made it. The full shot-by-shot script is in [DEMO_VIDEO_SCRIPT.md](../DEMO_VIDEO_SCRIPT.md).

| File | What it is |
| --- | --- |
| `WhatToEat-demo.mp4` | The demo, narrated by Apple's Siri voice Nora. macOS licenses its voices for personal, non-commercial use only, so use the Priya cut anywhere public. |
| `WhatToEat-demo-priya.mp4` | The same cut narrated by Sarvam Bulbul v3's Priya. |
| `demo-captions.srt`, `demo-captions-priya.srt` | Closed captions for each cut. |
| `tools/make_audio.py` | Generates the narration, the spoken prompts and the soundtrack (Sarvam, Gnani or Apple voices; keys from the project's `.env`). |
| `tools/apple_tts.swift` | Speaks lines with a macOS voice; run it with `swift`, which `make_audio.py` does for Apple narrators. |
| `pipeline/video_record.mjs` | Records takes A–E from the live app with Playwright (Chrome's fake mic plays the prompts). |
| `pipeline/video_render.mjs`, `pipeline/stage.html` | Cuts the takes, adds captions, tags, zooms and wipes, and renders the MP4 with ffmpeg. |

The pipeline scripts were run from a scratch folder and still point at it (`ROOT`, raw frames, ffmpeg path); change those paths before running them elsewhere. Take E opens the app with `?demo=heavy-day`, which logs a heavy breakfast and lunch so the light-dinner nudge shows.
