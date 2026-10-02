# WhatToEat

Decide what to eat in under a minute. Say or type what you're in the mood for —
*"I'm going out for dinner"*, *"got leftover rice and two eggs, want something quick"* —
and WhatToEat suggests three options that fit your taste and diet: dishes to cook (with an
AI-written recipe built around your ingredients), dishes to order in, or places to eat out
(with a suggested menu).

Built for urban Indian users: understands Hinglish and casual speech, and voice input is
transcribed in real time by an Indian-accent speech model.

**Live:** https://mosaic-seven-henna.vercel.app

## Features

- **Voice or text, in your own words** — an LLM understands intent ("heading out with
  friends tonight" → dinner, dining out), so there are no exact phrases to remember.
- **Real-time voice input** — mic audio streams to Gnani speech-to-text; words appear as
  you speak. The mic shows a "getting ready" state until the stream is live.
- **Three paths**
  - **Cook at home** — suggestions from the ingredients you have; the recipe is generated
    on the fly (prefetched in the background) with an optional healthier version.
  - **Order in** — dishes with calories and an "Order on Swiggy" link.
  - **Dine out** — restaurants with a suggested "what to order" menu and a Google Maps link.
- **Diet rules enforced server-side** — vegan sees only vegan; vegetarian sees vegetarian
  and vegan; eggetarian also sees egg dishes; non-veg sees everything.
- **Real dish photos** from Wikimedia Commons, matched to the dish name and checked
  against its diet.
- Onboarding (voice or text), meal logging, saved items, community recipes.

## Tech stack

| Layer | Tech |
| --- | --- |
| App | Flutter web (Provider, go_router), shown in an iPhone frame in the browser |
| Backend | Vercel Functions (Node.js) in `api/` |
| LLM | [Sarvam AI](https://docs.sarvam.ai) `sarvam-105b` |
| Speech-to-text | [Gnani Vachana](https://docs.gnani.ai) streaming STT over WebSocket |
| Images | Wikimedia Commons / Wikipedia APIs |

## Project structure

```
api/                    Vercel Functions
  intent.js             free-form text -> structured intent (meal, method, flavours, ...)
  suggestions.js        3 suggestions per request, diet-filtered, with dish photos
  recipe.js             on-the-fly recipe for a cook suggestion
  menu.js               suggested menu for a restaurant
  nudges.js             follow-up question chips
  stt-stream.js         WebSocket proxy: browser <-> Gnani streaming STT
  _sarvam.js            shared LLM helper (files starting with _ are not endpoints)
  _diet.js              diet rules and enforcement
  _images.js            Wikimedia dish-photo lookup
  community.js, transcribe.js   not used by the current app
lib/
  screens/              UI (onboarding, eat flow, suggestions, recipe, menu, ...)
  providers/            app state (eat flow, preferences, meal log, saved)
  services/             API clients (intent, recipes/menus, nudges, speech, links)
  widgets/              shared widgets (mic button, phone frame, ...)
  data/mock_data.dart   offline fallback content
web/
  gnani_streaming.js    mic capture -> 16 kHz PCM frames -> /api/stt-stream
  flutter_bootstrap.js  custom bootstrap (no service worker, see Notes)
build.sh                installs Flutter 3.24.3 and builds web on Vercel
```

## Setup

### Environment variables

Create `.env` in the project root (never commit it — it's in `.gitignore`):

```
SARVAM_API_KEY=your_sarvam_key
GNANI_API_KEY=your_gnani_key
```

Set the same two variables in **Vercel → Project → Settings → Environment Variables**
(Production).

### Deploy

```
vercel deploy --prod --force
```

`build.sh` installs Flutter and builds the web app on Vercel; `--force` skips the build
cache so every deploy is a clean build.

### Local development

Requires **Flutter 3.24.x** (the version `build.sh` pins; newer Flutter versions fail to
compile `lib/theme/app_theme.dart`). The UI runs locally with `flutter run -d chrome`, but the `api/` functions (and therefore
voice, suggestions, recipes and menus) only run on Vercel. Use `vercel dev` to run them
locally, or test against the deployed site.

## Notes and gotchas

- **Sarvam model:** `sarvam-m` is deprecated; only `sarvam-105b` works. It reasons by
  default, so calls pass `reasoning_effort: null` to stay fast.
- **Sarvam rate limits:** the key gets rate-limited after roughly 70 calls in a couple of
  minutes. Live intent analysis therefore only runs when the user pauses.
- **Gnani needs a proxy:** its WebSocket requires an `x-api-key-id` header, which browsers
  can't send, so the browser connects to `/api/stt-stream` and the function adds the header.
  Vercel WebSocket support is in public beta; sessions are capped at 5 minutes.
- **Intent grounding:** the LLM must quote the user's words for each value it extracts,
  and the server drops values whose quote isn't in the input — this stops invented answers.
- **No service worker:** an earlier build's service worker served stale files after
  redeploys. The app now registers none, and `build.sh` writes a cleanup worker that
  removes the old one from returning visitors' browsers.
- **Menus and restaurants are AI-suggested:** the app doesn't know the user's location,
  and menus/prices are illustrative, not official.
