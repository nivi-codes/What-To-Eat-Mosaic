# WhatToEat — 2-minute demo video script

Oct 3, 2026 · nivedita

## Overview

The finished video runs 1:59 in ten scenes: a title card, voice onboarding, the home page, cooking from what you have (by voice), the meal log, a gentle nudge toward a light dinner, planning a dinner out (by typing), ordering in (by typing), Community, and an end card.

![Scene timeline: ten scenes in 1:59, recorded in four takes](docs/images/demo-scene-timeline.png)

Take A covers scenes 1 and 2, take B scenes 3, 4, 6 and 8, take C scene 7, and take E scene 5; the cuts between takes hide under doodle wipes at 0:38.8, 1:06.5, 1:12.9, 1:36.8 and 1:47.2. The two spoken prompts land at 0:10 and 0:43.1.

- **Format:** 1920 × 1080, 30 fps. The app is recorded in Chrome, then placed on a cream canvas with the app's doodle wallpaper; all captions sit to the right of the phone.
- **Raw vs. final length:** the raw recording runs about 4 minutes, because AI answers take 5–15 seconds. Every wait is trimmed to 2–3 seconds in the edit (see Editing notes).
- **Voiceover throughout:** a narrator voice explains each step, and a second voice speaks the two prompts the app hears. All audio is pre-generated (see Voiceover and audio); nobody speaks during recording.

## Before you record

Record in four takes, with Chrome playing the generated prompt as its microphone, so the app hears exactly what viewers hear. Chrome's stand-in microphone plays one file per launch, so the onboarding prompt (take A) and the cooking prompt (take B) need separate launches. Takes C (ordering in) and E (the nudge) are typed, so they need no prompt.

- [ ] Use Google Chrome on a Mac. The demo runs in its own Chrome window with a separate profile, so your normal Chrome can stay open.
- [ ] **Take A** (scenes 1–2): run the take A command below in Terminal. It opens the app with the onboarding prompt as the microphone and mic permission already granted.
- [ ] **Take B** (scenes 3, 4, 6 and 8): close the take A window, run the take B command, then do onboarding off camera by typing: tap **Get started**, the keyboard icon (top right), type the onboarding sentence from Voiceover and audio, tap **Continue**, then **Start eating**. Start recording on the home page and keep it running through the Me page and Community; the edit moves the Me page up to right after cooking, and Community to after take C.
- [ ] **Take C** (scene 7): close the take B window, run the take C command, do the same typed onboarding off camera, and start recording on the home page. Take E (scene 5) works the same way with the take E command, which opens the app with a heavy breakfast and lunch already logged; record it after 5 pm so the nudge is about dinner.
- [ ] Record between 5 pm and 4 am local time, so the home header reads “What are we eating tonight?” (4–11 am it says “this morning”, 11 am–5 pm “today”).
- [ ] Leave 3 minutes between takes. The AI service throttles bursts of requests, and back-to-back takes get slow.
- [ ] After tapping a mic, wait: the prompt starts 4 seconds in and runs 5–7 seconds. Tap stop within 6 seconds of it ending, before the file loops.
- [ ] Screen recorder: Cmd + Shift + 5 → **Record Selected Portion**, drawn tightly around the phone frame. Under **Options**, set **Microphone** to **None**; all sound comes from the generated audio track.
- [ ] Notifications off (macOS Focus), and click highlighting on if your recorder has it (otherwise add click rings in the edit).

Take A command:

```bash
open -na "Google Chrome" --args --user-data-dir=/tmp/w2e-take-a --window-size=1280,1000 --use-fake-ui-for-media-stream --use-fake-device-for-media-stream --use-file-for-fake-audio-capture=$HOME/Downloads/WhatToEat-demo/voice-input/U1-onboarding-mic.wav https://mosaic-seven-henna.vercel.app
```

Take B command:

```bash
open -na "Google Chrome" --args --user-data-dir=/tmp/w2e-take-b --window-size=1280,1000 --use-fake-ui-for-media-stream --use-fake-device-for-media-stream --use-file-for-fake-audio-capture=$HOME/Downloads/WhatToEat-demo/voice-input/U2-cook-mic.wav https://mosaic-seven-henna.vercel.app
```

Take C command:

```bash
open -na "Google Chrome" --args --user-data-dir=/tmp/w2e-take-c --window-size=1280,1000 https://mosaic-seven-henna.vercel.app
```

Take E command:

```bash
open -na "Google Chrome" --args --user-data-dir=/tmp/w2e-take-e --window-size=1280,1000 "https://mosaic-seven-henna.vercel.app/?demo=heavy-day"
```

## Look of the video

Everything around the phone reuses the app's own design: a cream canvas, forest-ink outlines, bold tight type and the food doodles. The captions then read as part of the product.

**Canvas.** Cream `#FBF4E6` fills the 1920 × 1080 frame. The app's doodle wallpaper (the 36 doodles in `assets/doodles/`) is scattered over it at 18% opacity, fainter than in the app so captions stay readable.

**Phone.** The recorded phone frame is scaled to 960 px tall (about 457 px wide), centred at x = 600 px, with 60 px above and below. Nothing covers the phone screen except click rings and zoom-ins.

**Text zones** (frame coordinates in px, 0,0 = top-left):

| Zone | Position | Used for |
| --- | --- | --- |
| A · Scene pill | Caption area top: left edge x 1080, centre y 120 | Scene number and name, e.g. “1 · Set up by voice” |
| B · Headline card | Caption area middle: x 1080–1800, centred on y 430 | The one message of the moment, 8 words max, plus an optional sub-line |
| C · Voice subtitle | Caption area lower: x 1080–1800, y 700–860 | Exactly what you say into the app |
| D · Pointer tag | Gap between phone and captions: x 850–1060, at the height of the UI detail | Names a detail on screen, with a line to it |
| Full frame | Whole frame | Title card and end card only |

![Frame layout: the phone on the left, caption zones A–D on the right](docs/images/demo-frame-layout.png)

The scene pill (A) stays up for a whole scene, headline cards (B) change with the narration, and the subtitle (C) and pointer tags (D) appear only for their moment.

**Text styles:**

| Style | Shape | Type (Inter Tight, free on Google Fonts) | Colours |
| --- | --- | --- | --- |
| Scene pill | Fully rounded pill, 3 px ink outline, padding 12 × 24 px | ExtraBold 800, 26 px, letter-spacing −0.5 px | Turmeric `#F5B50F` fill, ink `#10372B` text, like the app's “Decide in 60 seconds” pill |
| Headline card | The app's offset card: white card, 4 px ink outline, 28 px corners, padding 28 × 36 px, on a lime block of the same size offset 14 px right and down (also ink-outlined) | Headline Black 900, 52 px, letter-spacing −1.5 px, line height 1.05; sub-line SemiBold 600, 28 px | Ink headline; sub-line `#5B6E66`; at most one key word in chilli `#E8412C` |
| Voice subtitle | Speech bubble: cobalt `#2D4BFF` fill, 4 px ink outline, 28 px corners, small tail pointing left at the phone, white mic icon at the start | Bold 700, 32 px, in quotes | White text |
| Pointer tag | The app's outline pill: white fill, 3 px ink outline; a 2 px ink line from the tag ends in a 12 px lime dot (ink outline) on the UI detail | Bold 700, 22 px | Ink text |
| Title and end card | Centred stack: W2E badge 360 px (`web/icons/Icon-512.png`), wordmark, turmeric pill | Wordmark Black 900, 120 px, letter-spacing −4 px | Ink on the cream doodle canvas |

**How text appears.** Motion copies the app's feel: quick and springy, nothing slower than 0.3 s.

- **Headline card in:** scales 92% → 100% and rises 24 px in 0.25 s (ease-out, slight overshoot). Its lime block slides out from behind to the 14 px offset 0.1 s later. **Out:** drops 16 px and fades in 0.2 s.
- **Scene pill:** slides in from 60 px right of its spot in 0.25 s at each scene start; between scenes, only its words cross-fade (0.15 s).
- **Voice subtitle:** the bubble pops in as you start speaking, and words appear one by one in step with your voice. It leaves 0.5 s after you tap stop.
- **Pointer tag:** the line draws from the tag to the detail in 0.2 s, then the tag pops in.
- **Sparkles:** on the three big moments (H2, H7, H12) two or three of the app's four-point sparkles (lime, blush, turmeric, 24–32 px, ink outline) pop at the headline card's corners once, for 0.4 s.
- **Scene change:** a doodle parade wipe. Six to eight doodles stream left to right across the frame along a wave in 0.7 s, the same motion as the in-app loader, hiding the cut.
- **Clicks:** a 48 px lime ring with a 3 px ink outline expands and fades at the click point (0.3 s).
- **Zoom-ins:** a 1.25× push onto the part of the phone a caption talks about: 0.4 s in, hold, 0.4 s out.

## Scene-by-scene script

Times are final-video times. While recording, just follow the order and wait for each screen; the edit trims the waits. Text IDs (S, H, V, D) are spelled out in On-screen text.

### Scene 0 · Title card · 0:00–0:03.7 (made in the editor)

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 0:00.0 | Title card: cream canvas, faint doodle wallpaper | — | VO01 at 0:00.3 | TITLE card builds in, full frame |
| 0:03.3 | Doodle parade wipe into the phone | — | — | — |

### Scene 1 · Set up by voice · 0:03.7–0:26.6 (take A)

Pages: Welcome → About you → You're all set!

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 0:03.7 | Welcome: W2E badge, “WhatToEat”, “Decide in 60 seconds”, **Get started** | Start recording take A on this page | — | S1 slides in (zone A) |
| 0:05.5 | Same | Click **Get started** (dark pill, bottom of the phone) | VO02 | H1 pops in (zone B) |
| 0:06.0 | About you: “Tell me about your everyday food preferences”, example pills, cobalt mic | — | — | — |
| 0:07.5 | Label under the mic: “Getting ready… hold on a sec” | Click the cobalt **mic** (bottom centre) | — | Click ring |
| 0:09.0 | Label turns “Speak now — tap to finish”, rings pulse | Hands off; the prompt plays by itself | — | — |
| 0:10.0 | Transcript box fills word by word above the mic; answer chips appear under it | Wait | U1 plays (7.1 s) | V1 in (zone C), word by word; D1 at 0:15.4 points at the chips |
| 0:18.0 | “Understanding what you said…” with a small doodle parade | Click the **stop** button (same spot) | VO03 | V1, D1 and H1 out |
| 0:20.0 | You're all set! Summary: “Vegetarian · Loves South Indian & Street Food · Usually spicy · Healthy options first” | Wait about 5 s | VO03 continues | H2 pops with sparkles; 1.25× zoom on the summary card, 0:20.5–0:24.5 |
| 0:25.5 | Same | Click **Start eating** (dark pill, bottom) | — | H2 out |

### Scene 2 · Home · 0:26.6–0:38.8 (take A)

Page: Home.

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 0:26.6 | Home: date and time, “What are we eating tonight?”, W2E badge, doodle wallpaper, “Tell me what you're craving” card, doodle categories | Wait 1.5 s | VO04 at 0:26.4 | S2 replaces S1; H3 pops in |
| 0:27.7 | Trending Now, Celebrity Chef Recipes, Star Recipes, Popular Restaurants | **Scroll down** with the trackpad, about 6 s | — | — |
| 0:33.9 | Star Recipes and Popular Restaurants, at the bottom of Home | Pause 0.5 s, then **scroll up** to the top, about 2.5 s | VO05 at 0:34.2 | H3 out; H4 pops in at 0:34.2 |
| 0:36.9 | Back at the header | Wait 2 s, then stop recording take A | — | H4 out at 0:38.6 |

### Scene 3 · Cook with what you have · 0:38.8–1:01.8 (take B)

Pages: Home → What do you want? → Your picks → Recipe → Home. Before recording take B, do onboarding by typing (see Before you record).

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 0:38.8 | Home (take B) | Start recording take B; at 0:39.1 click the **Tell me what you're craving** card | VO06 at 0:39.5 | Doodle parade wipe over the cut; S3 replaces S2; H5 pops in at 0:39.1 |
| 0:39.6 | What do you want?: “What are you in the mood for?”, cobalt mic | — | — | — |
| 0:41.1 | “Getting ready… hold on a sec” | Click the **mic** | — | Click ring |
| 0:43.1 | “Speak now”; the transcript fills word by word, and answer chips appear under it as they're understood (With: Paneer, Capsicum, Onions) | Wait | U2 plays (5.2 s) | V2 in (zone C), word by word |
| 0:49.1 | “Understanding what you said…”, then the doodle loader “Finding your picks…” with five answer chips under it: Meal: dinner · How: cook · Flavour: Spicy · With: Paneer, Capsicum, Onions · Time: 15 minutes (trim the loader to 3 s) | Click **stop** | VO07 at 0:49.2 | V2 out at 0:49.6; H6 replaces H5; D2 points at the answer chips, 0:50.2–0:52.8 |
| 0:52.8 | Your picks: “Here are 3 great options for you”; the first card shows **Healthy** already selected in lime | Wait 3 s | — | D3 points at the Regular / Healthy toggle, 0:53.3–0:55.6 |
| 0:55.8 | “Writing your recipe…” (trim to 1 s) | Click **View recipe** (dark pill, first card) | VO08 at 0:56.2 | H6, D3 out; H7 pops with sparkles |
| 0:56.8 | Recipe: photo, title, time · kcal · cuisine chips, Regular/Healthy toggle, nutrition, Ingredients, Method; **I'm having this** floats at the bottom | Wait 0.5 s | — | — |
| 0:57.4 | Ingredients, then Method | **Scroll down**, about 3.5 s | — | 1.25× zoom on Ingredients, 0:57.7–1:00.0 |
| 1:01.4 | Home, with a “Meal logged!” bar at the bottom | Click **I'm having this**, then wait on Home | — | H7 out |

### Scene 4 · Your meal log · 1:01.8–1:06.5 (take B)

Pages: Home → Me. Take B reaches the Me page after the dinner out (scene 6); the edit moves it here. Dining out adds nothing to Meal history, so it shows just the cooked dinner.

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 1:01.8 | Home: the “Meal logged!” bar, and a lime “… kcal today · 1 meal logged” card under the categories | — | VO09 at 1:02.2 | S4 replaces S3; H8 pops in at 1:02.0 |
| 1:02.8 | Me: Weekly balance (today's bar dark), My taste profile, and Meal history with the dinner from scene 3, its calories and the time it was logged | In take B, after scene 6: click **Me** (bottom bar, far right) and wait about 4 s, then go on to Community (scene 8) | — | D4 points at the dinner's row in Meal history, 1:03.8–1:06.2 |
| 1:06.3 | Doodle parade wipe to take E (scene 5) | — | — | H8, D4 out at 1:06.2 |

### Scene 5 · Gentle nudges · 1:06.5–1:12.9 (take E)

Pages: Home → Your picks. Take E opens the app as `mosaic-seven-henna.vercel.app/?demo=heavy-day`, which starts the day with a heavy breakfast (Aloo Paratha, 560 kcal) and lunch (Chole Bhature, 620 kcal) already logged. Record it after 5 pm, so the nudge is about dinner.

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 1:06.5 | Home (take E): under the craving card, a pink nudge card, “You've had Aloo Paratha and Chole Bhature today. How about something light for dinner?”, with **Show light dinner picks**; the lime card reads “1180 kcal today · 2 meals logged” | Start recording take E on Home and wait 3 s | VO10 at 1:06.8 | Doodle parade wipe over the cut; S5 replaces S4; H9 pops in at 1:06.8; 1.25× zoom on the nudge card, 1:06.9–1:08.9 |
| 1:08.9 | “Finding your picks…” with chips Meal: dinner · How: cook · Flavour: light · Time: 20 minutes (trim to 1.7 s) | Click **Show light dinner picks** | — | Click ring |
| 1:10.6 | Your picks: light home-cooked dinners with calories, such as Vegetable Upma (\~160 kcal, “Light and soothing”, “Easy to digest”) | Wait 3 s, then stop recording take E | — | D5 points at the first card's pills, 1:11.0–1:12.6; H9 out at 1:12.6 |
| 1:12.7 | Doodle parade wipe back to take B | — | — | — |

### Scene 6 · Going out · 1:12.9–1:36.8 (take B)

Pages: Home → What do you want? → What flavours → What's the vibe? → Your picks → Menu.

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 1:12.9 | Home | At 1:13.3 click the **Tell me what you're craving** card | VO11 at 1:13.5 | Doodle parade wipe from take E; S6 replaces S5; H10 pops in at 1:13.3 |
| 1:14.1 | What do you want? | Click **Type instead** (under the mic) | — | — |
| 1:14.9 | Text box and Continue | Click the text box and type **I am going out for dinner** | — | Zoom 1.25× on the text box, 1:14.9–1:18.1 |
| 1:17.1 | Chips “Meal: dinner · How: dine” under the box | Wait 1 s | — | D6 points at the chips |
| 1:18.1 | “Understanding…” (trim to 1 s) | Click **Continue** | — | H10, D6 out |
| 1:19.1 | “What flavours are you feeling?” Spicy / Light / Comforting / Sweet | — | VO12 at 1:19.1 | H11 pops in |
| 1:20.6 | Spicy turns lime | Click **Spicy**, then **Next** | — | — |
| 1:21.4 | “What's the vibe?” Casual / Quick bite / Something special / Surprise me | At 1:22.6 click **Casual** | — | — |
| 1:23.6 | Doodle loader “Finding your picks…” with chips Meal: dinner · How: dine · Flavour: Spicy · Vibe: casual (trim to 1 s) | Wait | — | H11 out |
| 1:24.6 | Your picks: “Here are 3 places worth heading out to”; restaurant cards with a dish photo, cuisine · vibe · ₹₹, highlight pills, **View menu**; no calories | Wait about 5 s | VO13 at 1:24.8 | H12 pops with sparkles |
| 1:29.4 | — | Click **View menu** on the first card | — | H12 out |
| 1:30.4 | Menu: photo, name, **Find on Google Maps**, “What to order” sections with green veg marks and ₹ prices; **Let's go here** floats at the bottom. If “Pulling up the menu…” shows, trim it to 1 s | Wait 1 s | VO14 at 1:31.0 | H13 pops in; D7 points at the end of the first dish's row, 1:30.4–1:31.4 |
| 1:31.4 | Starters and Mains with prices, **Find on Google Maps** still near the top | **Scroll down** slowly, about 3 s, and stop while Find on Google Maps is still on screen | — | — |
| 1:34.4 | Same, still | Wait 3 s, then click **Let's go here** and carry on to the Me page (scene 4); the edit cuts before this tap | — | D8 points at Find on Google Maps, 1:34.5–1:36.6, as VO14 says “Google Maps”; H13 out at 1:36.6 |

### Scene 7 · Ordering in · 1:36.8–1:47.2 (take C)

Pages: Home → What do you want? → Your picks. Before recording take C, do onboarding by typing.

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 1:36.8 | Home (take C) | Start recording take C; at 1:37.1 click the **Tell me what you're craving** card | VO15 at 1:37.4 | Doodle parade wipe over the cut; S7 replaces S6; H14 pops in at 1:37.1 |
| 1:37.9 | What do you want? | Click **Type instead** | — | — |
| 1:38.6 | Text box and Continue | Click the text box and type **Order in a spicy dinner, any cuisine** | — | — |
| 1:40.0 | Chips “Meal: dinner · How: order · Flavour: Spicy · Cuisine: Any” (no follow-up questions needed) | Wait 0.5 s | — | — |
| 1:40.5 | — | Click **Continue** | — | — |
| 1:41.1 | Doodle loader with the same four chips (trim to 0.6 s) | Wait | — | H14 out |
| 1:41.7 | Your picks: delivery dishes, each with a restaurant, time, price, calories and **Order on Swiggy** | Wait about 3 s | VO16 at 1:41.7 | H15 pops in |
| 1:45.0 | Unchanged; a new browser tab opens Swiggy's search for that dish | Click **Order on Swiggy** on the first card | — | D9 points at the button, 1:45.1–1:47.2 |
| 1:47.2 | — | Stop recording take C | — | H15, D9 out |

### Scene 8 · Community · 1:47.2–1:51.9 (take B)

Page: Community. This is the end of take B, recorded straight after the Me page in scene 4.

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 1:47.2 | Me (take B) | At 1:47.5 click **Community** (bottom bar, second from left) | VO17 at 1:47.6 | Doodle parade wipe over the cut; S8 replaces S7; H16 pops in at 1:47.5 |
| 1:47.5 | Community: filter chips (All, Trending, Breakfast, Lunch …) over ranked recipe cards, each with a photo, author, likes, cooking time and tags; only dishes that fit the profile's diet are listed | Wait 1.5 s | — | — |
| 1:49.1 | More recipes | **Scroll down**, about 2 s | — | — |
| 1:51.1 | — | Stop recording take B | — | H16 out at 1:51.7 |

### Scene 9 · End card · 1:51.9–1:59.8 (made in the editor)

| Time | On screen | Do this | Audio | Text on screen |
| --- | --- | --- | --- | --- |
| 1:51.6 | Doodle parade wipe out of the phone | — | — | S8 out |
| 1:52.3 | End card: cream canvas, faint doodle wallpaper | — | VO18 at 1:52.8 | END card builds in, full frame |
| 1:58.9 | Fade to cream | — | — | — |

## Voiceover and audio

All sound is generated in advance, so nobody speaks during recording. A narrator reads 18 short lines, and a second voice speaks the user's two prompts. One file, `demo-audio-track.wav`, already holds every clip at its time: put it on the timeline at 0:00 and fit the picture to it.

### Voices

- **Narrator: Apple's Siri voice Nora** (female, US English), built into macOS. Sarvam's check heard every word; Gnani's misheard only the dish names and “picks” as “pics”. At 3.0 words a second, every line fits its slot with room to spare. Apple's licence limits it to personal, non-commercial use (below), so the same cut narrated by Sarvam Bulbul v3's Priya (female, Indian English) is ready as WhatToEat-demo-priya.mp4.
- **User: Gnani Timbre v2.5, voice Kaveri** (female, Indian English). Sounds like someone talking to an app, and the app's own speech-to-text heard her word for word. Her lines come with the cobalt subtitle bubble, so the two voices stay easy to tell apart.

**How they were picked.** In the first round, two Apple voices, six Sarvam voices and six Gnani voices each read one narration line (VO03) and one user prompt (U2). Every recording was transcribed back by both Gnani's and Sarvam's speech-to-text, and each word that came back wrong counted against the voice. A second round found the female narrator: twelve Bulbul v3 female voices read the two hardest narration lines (VO03 and VO07) through the same check. A third round tried Apple's voices for the narrator: Siri's Nora and Riya read all 17 lines, and Samantha and the enhanced Tara read VO03.

| Female narrator (Bulbul v3) | Words wrong, of 72 heard | Pace (words/s) | Result |
| --- | --- | --- | --- |
| Priya | 0 | 2.5 | **Narrator** |
| Roopa, Shruti | 0 | 2.4–2.5 | Equally clear |
| Neha | 0 | 2.1 | Clear, but slow |
| Shreya, Tanya, Simran | 0 | 2.9–3.1 | Clear, but brisker |
| Pooja, Ishita, Suhani, Rupali | 1 | 2.3–3.0 | One word misheard |
| Kavitha | 2 | 2.2 | Two words misheard |

The same check caught three things in Priya's narration: “meal” once came out as “mail” (that line was later rewritten), “Just” in VO06 and “Eating” in VO09 came out unclear at normal speed (both are read at 0.92×), and she reads “it'll” as “it will”, so VO13 is written that way.

Third round, Apple's voices:

| Apple voice | Words wrong, Gnani / Sarvam | Pace (words/s) | Result |
| --- | --- | --- | --- |
| Nora (Siri, US English) | 6 / 1, of 234 | 3.0 | Narrator |
| Riya (Siri, Indian English) | 9 / 7, of 234 | 2.9 | Clear, but more slips |
| Samantha (US English) | 2 / 2, of 19 | 2.9 | Robotic; “dosas” and “chaat” misheard |
| Tara, enhanced (Indian English) | 14 / 13, of 19 | — | Garbled |

First round, for the record:

| Voice | Narration line: words wrong (Gnani / Sarvam check) | User prompt: words wrong | Pace (words/s) | Result |
| --- | --- | --- | --- | --- |
| Sarvam Aditya | 0% / 0% | 11%\* | 2.6 | Narrator in the first cut (male) |
| Sarvam Shubh | 0% / 0% | 11%\* | 3.5 | Clear, but brisker |
| Sarvam Priya, Kavya, Ritu, Rohan | 0–10% | 11%\* | 2.2–3.1 | A word or two misheard |
| Gnani Kaveri | 0% / 0% | 0% | 3.3 | **User voice** |
| Gnani Pranav | 0% / 0% | 0% | 3.1 | Best male alternative |
| Gnani Girish, Shlok, Devika, Trupti | 0–20% | 0% | 3.1–3.7 | A word or two misheard |
| Apple Aman, Tara (built into macOS) | 5–65% | 0% | — | Not allowed in a published video |

\*Every Sarvam voice says “I've” as “I have”. That's harmless in narration, but in a user prompt the subtitle would no longer match what viewers hear.

**Apple's licence.** The macOS licence lets the voices that come with macOS, Siri's included, be used only “to create your own original content and projects for your personal, non-commercial use”, and rules out “publishing or redistribution … in a profit, non-profit, public sharing or commercial context” ([macOS Tahoe 26 licence](https://www.apple.com/legal/sla/docs/macOSTahoe.pdf), section 2F; the macOS 27 licence on this Mac says the same). So the Nora cut suits reviewing the edit, and the Priya cut is the one to publish. In the first round, the older Apple voices also did worst: Aman cut the test line short, and Tara's was misheard in places.

### Narration

Files: `voiceover/VO01.wav` to `VO18.wav` (48 kHz, mono), read by Nora. Each clip ends before the next sound starts. Priya's reading of the same lines is in `voiceover-priya/`, and the first cut's male narration in `voiceover-aditya/`.

| ID | Starts | Runs | Line |
| --- | --- | --- | --- |
| VO01 | 0:00.3 | 4.8 s | WhatToEat is an app that literally helps you decide what to eat in under a minute. |
| VO02 | 0:05.5 | 4.0 s | Setting up takes one sentence. Just tell it your food preferences. |
| VO03 | 0:18.0 | 6.9 s | It transcribes as you speak, then works out what you meant: dosas and chaat become South Indian and street food. |
| VO04 | 0:26.4 | 6.6 s | Home changes with the time of day, with quick picks, trending dishes, chef recipes and popular restaurants. |
| VO05 | 0:34.2 | 4.6 s | It helps with all three: cooking at home, ordering in, and dining out. |
| VO06 | 0:39.5 | 2.9 s | Cooking tonight? Just say what's in the kitchen. |
| VO07 | 0:49.2 | 5.4 s | One sentence answered all five questions. Every pick is vegetarian, like the profile. |
| VO08 | 0:56.2 | 3.7 s | The recipe is written on the spot, around the ingredients you actually have. |
| VO09 | 1:02.2 | 3.3 s | You can also log your meals, and it will save them to your daily log. |
| VO10 | 1:06.8 | 3.4 s | Had a heavy day? It gently nudges you toward a light dinner. |
| VO11 | 1:13.5 | 3.6 s | Eating out instead? Typing works just as well. |
| VO12 | 1:19.1 | 3.5 s | It asks only what it still needs: flavour, then the vibe. |
| VO13 | 1:24.8 | 5.8 s | For a night out, you get places to go, not calories to count, each with a suggested order. |
| VO14 | 1:31.0 | 5.2 s | The menu keeps to vegetarian dishes, with prices, and a link to find the place on Google Maps. |
| VO15 | 1:37.4 | 2.8 s | Staying in? Ask for delivery the same way. |
| VO16 | 1:41.7 | 4.8 s | Each pick shows its calories, and Order on Swiggy opens the dish, ready to order. |
| VO17 | 1:47.6 | 4.1 s | And Community has recipes other people love, filtered to your diet. |
| VO18 | 1:52.8 | 6.0 s | Cook, order in, or dine out. WhatToEat: decide what to eat in under a minute. |

### The user's prompts

| ID | Scene | Starts · runs | Words (the subtitle shows exactly these) | What the app picked up (live site, 3 Oct) |
| --- | --- | --- | --- | --- |
| U1 | 1 · Set up by voice | 0:10.0 · 7.1 s | I'm vegetarian. I'm a big fan of dosas and chaat, I love spicy food, I have no allergies, and I prefer healthy options. | Vegetarian · South Indian + Street Food · Spicy · No allergies · Healthy first |
| U2 | 3 · Cook with what you have | 0:43.1 · 5.2 s | I've got paneer, capsicum and onions at home. I want to cook something quick and spicy for dinner. | Dinner · Cook · Spicy · Paneer, Capsicum, Onions · 15 minutes |

Each prompt has two files in `voice-input/`: the clip itself (`U1-onboarding.wav`, `U2-cook.wav`) for the edit, and a `-mic` copy with 4 s of silence before and 8 s after, which Chrome plays as its microphone while you record.

### Typed text

- **Takes B and C, off camera:** the onboarding answer, typed exactly as U1 reads: I'm vegetarian. I'm a big fan of dosas and chaat, I love spicy food, I have no allergies, and I prefer healthy options.
- **Scene 6, on camera:** I am going out for dinner
- **Scene 7, on camera:** Order in a spicy dinner, any cuisine

### Files

All in `~/Downloads/WhatToEat-demo/`:

| File | What it is |
| --- | --- |
| `WhatToEat-demo.mp4` | The finished video, narrated by Nora: 1:59, 1920 × 1080, 30 fps, H.264 with AAC audio |
| `demo-audio-track.wav` | The finished soundtrack without music: 1:59, every clip at its time, 48 kHz mono |
| `demo-captions.srt` | Closed captions for every spoken line |
| `voiceover/VO01.wav` … `VO18.wav` | The narrator's lines |
| `WhatToEat-demo-priya.mp4`, `demo-audio-track-priya.wav`, `demo-captions-priya.srt`, `voiceover-priya/` | The same cut narrated by Priya, for public use |
| `voice-input/U1-onboarding.wav`, `U2-cook.wav` | The two prompts, for the edit |
| `voice-input/U1-onboarding-mic.wav`, `U2-cook-mic.wav` | Padded copies for Chrome's microphone |
| `WhatToEat-demo-aditya.mp4`, `voiceover-aditya/`, `demo-audio-track-aditya.wav` | The first cut, with the male narrator |
| `voice-comparison/`, `voice-comparison-results.json` | Samples and scores from the voice tests (`voice-comparison/female/` for the second round, `voice-comparison/apple/` for Apple's voices) |
| `tools/make_audio.py` | Regenerates any of the above audio |
| `tools/apple_tts.swift` | Speaks lines with a macOS voice; `make_audio.py` uses it for Apple narrators |

### Changing a line or a voice

`make_audio.py` holds every line, start time and voice. It reads the API keys from the project's `.env` and needs nothing installed, except Xcode's command line tools for Apple voices.

1. In `tools/make_audio.py`, edit the line in `VO` or the words in `PROMPTS`, or change `NARRATOR` or `USER_VOICE`; for example `NARRATOR = ('sarvam', 'priya')` brings back Priya, and ('apple', 'com.apple.siri.natural.Riya') tries Siri's Indian English voice. A fifth value on a `VO` line sets its speed.
2. Run, in Terminal:

```bash
cd ~/Downloads/WhatToEat-demo
python3 tools/make_audio.py voiceover VO05   # one clip; leave out the ID for all 18
python3 tools/make_audio.py prompts          # after changing a prompt or the user voice
python3 tools/make_audio.py track            # rebuild the full track
```

If a new line is too long for its slot, the script first speeds the voice up slightly, then says so if it still doesn't fit. Changing a prompt's words also means updating its subtitle (V1 or V2) and re-recording that take, because the app hears the new words.

## On-screen text

Every word that appears on screen, in order. Shapes, type and motion are set in Look of the video; zones A–D are the caption areas to the right of the phone. In a headline, the **bold** word is the one set in chilli red.

### Title and end cards (full frame)

| ID | In → out | Stack, top to bottom | How it appears |
| --- | --- | --- | --- |
| TITLE | 0:00.0 → 0:03.7 | W2E badge (360 px) · wordmark “WhatToEat” · turmeric pill “Decide what to eat in 60 seconds” | Badge pops in, scaling 80% → 100% while turning from −10° to 0° (0.35 s); wordmark rises 24 px into place at 0:00.4; pill slides in from the right at 0:00.8. Leaves with the doodle parade wipe at 0:03.3. |
| END | 1:52.3 → 1:59.8 | W2E badge · “WhatToEat” · turmeric pill “Cook · Order in · Dine out” · outline pill “mosaic-seven-henna.vercel.app” | Badge and wordmark build as on TITLE; the turmeric pill slides in at 1:53.4; the URL pill pops in at 1:55.5, as VO18 says “WhatToEat”. Everything fades to cream from 1:58.9. |

### Scene pills (zone A)

| ID | Words | In → out |
| --- | --- | --- |
| S1 | 1 · Set up by voice | 0:03.7 → 0:26.6 |
| S2 | 2 · Your home screen | 0:26.6 → 0:38.8 |
| S3 | 3 · Cook with what you have | 0:38.8 → 1:01.8 |
| S4 | 4 · Your meal log | 1:01.8 → 1:06.5 |
| S5 | 5 · Gentle nudges | 1:06.5 → 1:12.9 |
| S6 | 6 · Going out tonight | 1:12.9 → 1:36.8 |
| S7 | 7 · Ordering in | 1:36.8 → 1:47.2 |
| S8 | 8 · Community | 1:47.2 → 1:51.7 |

S1 slides in from the right; at each later change the old words fade out, then the new ones fade in. S8 leaves with the closing doodle wipe.

### Headline cards (zone B)

| ID | Headline | Sub-line | In → out | Extra |
| --- | --- | --- | --- | --- |
| H1 | Just **tell** it your food preferences | No forms. One sentence sets up your profile. | 0:05.5 → 0:18.0 |  |
| H2 | “Dosas and chaat” **→** South Indian + Street Food | It reads meaning, not keywords | 0:20.0 → 0:25.5 | Sparkles |
| H3 | **Every** meal starts here | Changes with the time of day | 0:26.6 → 0:33.9 |  |
| H4 | It helps with all **three** | Cooking at home, ordering in and dining out | 0:34.2 → 0:38.6 |  |
| H5 | Say what's in your **kitchen** | — | 0:39.1 → 0:49.1 |  |
| H6 | Picks that fit your **diet** | All vegetarian, like your profile | 0:49.1 → 0:55.6 | Replaces H5 directly |
| H7 | A recipe written for your **fridge** | Built around the ingredients you have | 0:55.8 → 1:01.4 | Sparkles |
| H8 | Your daily **log** | Every meal you pick, with its calories | 1:02.0 → 1:06.2 |  |
| H9 | Heavy day? Go **light** | It nudges you toward a light dinner | 1:06.8 → 1:12.6 |  |
| H10 | Or just **type** it | — | 1:13.3 → 1:18.1 |  |
| H11 | Asks only what's **missing** | — | 1:19.1 → 1:23.6 |  |
| H12 | **Places** to go, not calories to count | Each with a suggested order | 1:24.6 → 1:29.4 | Sparkles |
| H13 | What to **order**, with prices | Plus a Google Maps link | 1:30.4 → 1:36.6 |  |
| H14 | Too tired to cook? **Order** in | Same box, plain words | 1:37.1 → 1:41.1 |  |
| H15 | Ready to order on **Swiggy** | Calories on every pick | 1:41.7 → 1:47.2 |  |
| H16 | Recipes people **love** | Filtered to your diet | 1:47.5 → 1:51.7 |  |

### Voice subtitles (zone C)

| ID | Words | In → out |
| --- | --- | --- |
| V1 | “I'm vegetarian. I'm a big fan of dosas and chaat, I love spicy food, I have no allergies, and I prefer healthy options.” | 0:10.0 → 0:18.5 |
| V2 | “I've got paneer, capsicum and onions at home. I want to cook something quick and spicy for dinner.” | 0:43.1 → 0:49.6 |

The bubble pops in with the first word; the words then appear one at a time in step with U1 or U2 (up to three lines), and the bubble leaves 0.5 s after the stop tap.

### Pointer tags (zone D)

| ID | Words | Points at | In → out |
| --- | --- | --- | --- |
| D1 | Picked up as you speak | The answer chips under the transcript box (About you) | 0:15.4 → 0:18.0 |
| D2 | 5 answers from 1 sentence | The five answer chips under “Finding your picks…” | 0:50.2 → 0:52.8 |
| D3 | Lighter version: fewer kcal | The Regular / Healthy toggle on the first card | 0:53.3 → 0:55.6 |
| D4 | Saved with its calories | The end of the dinner's row in Meal history, on the Me page | 1:03.8 → 1:06.2 |
| D5 | Light and easy to digest | The end of the first light pick's pills (“Light and soothing”) | 1:11.0 → 1:12.6 |
| D6 | Dinner + dining out | The chips “Meal: dinner · How: dine” under the text box | 1:17.1 → 1:18.1 (hold 1 s longer; see Editing notes) |
| D7 | Veg only, as per your profile | The end of the first dish's row on the menu, by its price | 1:30.4 → 1:31.4 |
| D8 | Opens in Google Maps | The end of the **Find on Google Maps** button, after the short menu scroll | 1:34.5 → 1:36.6 |
| D9 | Opens Swiggy, dish already searched | The **Order on Swiggy** button on the first pick | 1:45.1 → 1:47.2 |

Each tag sits level with its detail: the line draws first (0.2 s), then the tag pops in.

### Also on screen (no words)

- Click rings at every tap (0.3 s, lime with an ink outline).
- Zoom-ins: the summary card 0:20.5–0:24.5, Ingredients 0:57.7–1:00.0, the nudge card 1:06.9–1:08.9, the text box 1:14.9–1:18.1.
- Doodle parade wipes: 0:03.3 (into the phone), 0:38.5, 1:06.3, 1:12.7, 1:36.5 and 1:46.9 (hide the cuts between takes), 1:51.6 (out to the end card).

## Editing notes

Any editor works (CapCut, iMovie, DaVinci Resolve, Premiere). Work in this order:

1. **Lay the audio first.** Put `demo-audio-track.wav` on the timeline at 0:00 and lock it. Every time in this script comes from it: cut the picture to fit the sound, never the other way round.
2. **Join the takes.** Take A fills 0:03.7–0:38.8, take B 0:38.8–1:06.5, 1:12.9–1:36.8 and 1:47.2–1:51.9, take E 1:06.5–1:12.9, and take C 1:36.8–1:47.2. Two parts of take B move: the Me page goes right after cooking (1:02.8–1:06.5), and Community goes after take C. Make every cut between takes (0:38.8, 1:06.5, 1:12.9, 1:36.8 and 1:47.2) under a doodle parade wipe.
3. **Line up each prompt.** The recordings are silent, and Chrome starts the prompt about 4 seconds after the mic tap. Shorten the “Speak now” wait so the tap lands where the scene table puts it (0:07.5 for U1, 0:41.1 for U2); the first words then appear on screen about a second after the voice starts.
4. **Trim the AI waits.** Keep 2–3 s of each “Finding your picks…” loader and about 1 s of “Understanding…”, “Writing your recipe…” and “Pulling up the menu…”, and cut the rest. The doodles never stop moving, so put a 4-frame cross-dissolve on every cut inside a loader.
5. **Give D6 a second more.** The dine chips are on screen for only 1 s before the Continue tap. Freeze that frame for one extra second and take the second back from the “Understanding…” wait after it.
6. **Voice subtitles.** Run your editor's auto-captions on `U1-onboarding.wav` and `U2-cook.wav` only, in a word-by-word style, then restyle them as the cobalt bubble. Check the words against V1 and V2: auto-captions often misspell “chaat” and “capsicum”.
7. **Captions for muted autoplay.** `demo-captions.srt` in the demo folder holds every spoken line with its time. Attach it as closed captions when uploading; don't burn it in, since the headline cards already fill the caption area.
8. **Music (optional).** Something light and bright, ducked about 20 dB under every voice clip, fading out from 1:58 under the end card.
9. **Export.** 1920 × 1080, 30 fps, H.264 at about 12 Mbps, AAC 48 kHz. The finished file runs 1:59.

## If something goes wrong

The AI answers differently on every run, so a take can come out slightly different from the script. Most of it is fixed in the edit; redo a take only where this table says so.

| What happens | What to do |
| --- | --- |
| A follow-up question appears after you speak (for example “What flavours are you feeling?”) | The app missed one answer. Tap the answer the prompt gave and carry on; cut the question out in the edit. |
| The first words are missing from the transcript | The connection opened slowly. Close the window, run the take's command again and redo the take. |
| The prompt starts playing a second time | Stop was tapped too late and the file looped. Redo the take, tapping stop within 6 seconds of the prompt ending. |
| The first card has no Regular / Healthy toggle, or shows the fork-and-knife placeholder instead of a photo | Tap **Surprise me** (top right) for a fresh set of three, and cut that out in the edit. Avoid **Not feeling it**: it swaps in a built-in example dish, not a new AI pick. A placeholder on the half-visible second card can stay. |
| The picks ignore paneer, capsicum and onions | The AI service was busy, so the app fell back to built-in examples. Wait 3 minutes, then redo the take. |
| An AI step takes more than 15 seconds | Keep recording; the wait is trimmed in the edit. |
| Home says “today” or “this morning” instead of “tonight” | The headline follows the clock: record between 5 pm and 4 am. |
| Chrome asks for microphone permission | The take command should grant it. If Chrome still asks, click Allow, close the window and run the command again. |
| Tapping Order on Swiggy seems to do nothing | It opens Swiggy's search for that dish in a new browser tab; the app itself doesn't change. Keep recording the app's window and close the Swiggy tab afterwards. |
