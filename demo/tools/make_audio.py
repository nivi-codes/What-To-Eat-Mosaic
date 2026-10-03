#!/usr/bin/env python3
"""Regenerates the audio for the WhatToEat demo video.

  python3 make_audio.py voiceover [VO05 VO09 ...]  narrator clips   -> ../voiceover/
  python3 make_audio.py prompts                     the user's lines -> ../voice-input/
  python3 make_audio.py track                       mixes every clip -> ../demo-audio-track.wav
  python3 make_audio.py all                         all three, in that order

API keys come from SARVAM_API_KEY / GNANI_API_KEY, or from ~/Downloads/mosaic/.env.
Standard library only; Apple voices also need macOS with Xcode's command line tools (for `swift`).
"""
import array
import base64
import json
import os
import subprocess
import sys
import tempfile
import urllib.request
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path.home() / 'Downloads' / 'mosaic' / '.env'
RATE = 48000
LENGTH = 119.8  # seconds: the finished video runs 1:59.8

# Swap voices here: ('sarvam', '<Bulbul v3 speaker>'), ('gnani', '<Timbre v2.5 voice>') or
# ('apple', '<macOS voice identifier>'); `swift apple_tts.swift list` prints the identifiers.
NARRATOR = ('apple', 'com.apple.siri.natural.Nora')
USER_VOICE = ('gnani', 'Kaveri')

# [id, start in the video (s), longest it may run (s), line, optional speed]
# "Longest" leaves at least 0.3 s before the next sound starts.
VO = [
    ('VO01', 0.3, 4.9, 'WhatToEat is an app that literally helps you decide what to eat in under a minute.'),
    ('VO02', 5.5, 4.2, 'Setting up takes one sentence. Just tell it your food preferences.'),
    ('VO03', 18.0, 8.1, 'It transcribes as you speak, then works out what you meant: dosas and chaat become South Indian and street food.'),
    ('VO04', 26.4, 7.5, 'Home changes with the time of day, with quick picks, trending dishes, chef recipes and popular restaurants.'),
    ('VO05', 34.2, 5.0, 'It helps with all three: cooking at home, ordering in, and dining out.'),
    ('VO06', 39.5, 3.3, "Cooking tonight? Just say what's in the kitchen.", 0.92),  # slower, so "Just" isn't swallowed
    ('VO07', 49.2, 6.7, 'One sentence answered all five questions. Every pick is vegetarian, like the profile.'),
    ('VO08', 56.2, 5.7, 'The recipe is written on the spot, around the ingredients you actually have.'),
    ('VO09', 62.2, 4.3, "You can also log your meals, and it will save them to your daily log."),
    ('VO10', 66.8, 6.3, 'Had a heavy day? It gently nudges you toward a light dinner.'),
    ('VO11', 73.46, 5.3, 'Eating out instead? Typing works just as well.', 0.92),  # slower, so "Eating" isn't swallowed
    ('VO12', 79.1, 5.4, 'It asks only what it still needs: flavour, then the vibe.'),
    ('VO13', 84.8, 5.9, 'For a night out, you get places to go, not calories to count, each with a suggested order.'),
    ('VO14', 91.0, 6.1, 'The menu keeps to vegetarian dishes, with prices, and a link to find the place on Google Maps.'),
    ('VO15', 97.4, 4.0, 'Staying in? Ask for delivery the same way.'),
    ('VO16', 101.7, 5.6, 'Each pick shows its calories, and Order on Swiggy opens the dish, ready to order.'),
    ('VO17', 107.57, 4.9, 'And Community has recipes other people love, filtered to your diet.'),
    ('VO18', 112.8, 6.1, 'Cook, order in, or dine out. WhatToEat: decide what to eat in under a minute.'),
]

# [file name, start in the video (s), words]
PROMPTS = [
    ('U1-onboarding', 10.0, "I'm vegetarian. I'm a big fan of dosas and chaat, I love spicy food, I have no allergies, and I prefer healthy options."),
    ('U2-cook', 43.1, "I've got paneer, capsicum and onions at home. I want to cook something quick and spicy for dinner."),
]
# Silence around each prompt in the -mic copies Chrome plays as its microphone: the
# prompt starts after the app is listening, and stop is tapped before the file loops.
MIC_PAD = (4.0, 8.0)


def api_key(name):
    if os.environ.get(name):
        return os.environ[name]
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            k, _, v = line.partition('=')
            if k.strip() == name:
                return v.strip().strip('"\'')
    sys.exit(f'{name} not set (env or {ENV_FILE})')


def post(url, headers, body):
    req = urllib.request.Request(url, json.dumps(body).encode(), {**headers, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def tts(voice, text, speed=1.0):
    provider, name = voice
    if provider == 'apple':
        # AVSpeechUtterance's rate, where 0.5 is the voice's own pace.
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'line.wav'
            subprocess.run(['swift', str(Path(__file__).with_name('apple_tts.swift')), name, f'{0.5 * speed:.3f}', str(out), text], check=True)
            return load(out)
    if provider == 'sarvam':
        reply = post('https://api.sarvam.ai/text-to-speech', {'api-subscription-key': api_key('SARVAM_API_KEY')}, {
            'text': text, 'language_code': 'en-IN', 'speaker': name, 'model': 'bulbul:v3',
            'pace': speed, 'speech_sample_rate': RATE, 'output_audio_codec': 'wav'})
        return read_pcm(base64.b64decode(json.loads(reply)['audios'][0]))
    reply = post('https://api.vachana.ai/api/v1/tts/inference', {'X-API-Key-ID': api_key('GNANI_API_KEY')}, {
        'text': text, 'voice': name, 'model': 'timbre-v2.5', 'language': 'en-IN', 'speed': speed,
        'audio_config': {'sample_rate': RATE, 'num_channels': 1, 'sample_width': 2, 'encoding': 'linear_pcm', 'container': 'wav'}})
    return read_pcm(reply)


def read_pcm(data):
    """WAV bytes -> mono 16-bit samples at RATE. Streamed WAVs carry a placeholder data
    size, so the data chunk is clamped to the bytes actually present."""
    off, rate, channels = 12, RATE, 1
    while off + 8 <= len(data):
        cid, size = data[off:off + 4], int.from_bytes(data[off + 4:off + 8], 'little')
        if cid == b'fmt ':
            channels = int.from_bytes(data[off + 10:off + 12], 'little')
            rate = int.from_bytes(data[off + 12:off + 16], 'little')
        if cid == b'data':
            raw = data[off + 8:off + 8 + min(size, len(data) - off - 8)]
            samples = array.array('h', raw[:len(raw) // 2 * 2])
            if channels > 1:
                samples = array.array('h', samples[::channels])
            return resample(samples, rate)
        off += 8 + size + (size % 2)
    sys.exit('not a WAV file')


def resample(samples, rate):
    if rate == RATE or not samples:
        return samples
    n = int(len(samples) * RATE / rate)
    step = rate / RATE
    out = array.array('h', bytes(2 * n))
    for i in range(n):
        x = i * step
        j = int(x)
        nxt = samples[min(j + 1, len(samples) - 1)]
        out[i] = int(samples[j] + (nxt - samples[j]) * (x - j))
    return out


def load(path):
    return read_pcm(path.read_bytes())


def save(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(samples.tobytes())


def secs(samples):
    return len(samples) / RATE


def silence(seconds):
    return array.array('h', bytes(2 * int(seconds * RATE)))


def make_voiceover(only):
    top = 1.15 if NARRATOR[0] == 'gnani' else 1.2  # faster starts to sound rushed (Gnani's maximum is 1.15)
    for vid, _, longest, line, *opt in VO:
        if only and vid not in only:
            continue
        speed = opt[0] if opt else 1.0
        for _ in range(3):
            clip = tts(NARRATOR, line, speed)
            if secs(clip) <= longest:
                break
            speed = round(min(top, speed * secs(clip) / longest + 0.02), 2)  # speed up a little to fit
        save(ROOT / 'voiceover' / f'{vid}.wav', clip)
        fits = 'fits' if secs(clip) <= longest else f'TOO LONG for its {longest}s slot: shorten the line'
        print(f'{vid}  {secs(clip):5.2f}s  speed {speed}  {fits}')


def make_prompts():
    for name, _, words in PROMPTS:
        clip = tts(USER_VOICE, words)
        save(ROOT / 'voice-input' / f'{name}.wav', clip)
        save(ROOT / 'voice-input' / f'{name}-mic.wav', silence(MIC_PAD[0]) + clip + silence(MIC_PAD[1]))
        print(f'{name}  {secs(clip):5.2f}s  (+ {name}-mic.wav)')


def make_track():
    mix = array.array('i', bytes(4 * int(LENGTH * RATE)))
    placed = [(vid, start, ROOT / 'voiceover' / f'{vid}.wav') for vid, start, *_ in VO]
    placed += [(name, start, ROOT / 'voice-input' / f'{name}.wav') for name, start, _ in PROMPTS]
    spans = []
    for label, start, path in sorted(placed, key=lambda p: p[1]):
        clip = load(path)
        at = int(start * RATE)
        for i, s in enumerate(clip[:max(0, len(mix) - at)]):
            mix[at + i] += s
        end = start + secs(clip)
        clash = [other for other, s0, e0 in spans if s0 < end and start < e0]
        spans.append((label, start, end))
        print(f'{label:14s} {start:6.1f}-{end:6.1f}s' + (f'  OVERLAPS {", ".join(clash)}' if clash else '')
              + ('  RUNS PAST THE END' if end > LENGTH else ''))
    peak = max(map(abs, mix)) or 1
    gain = min(1.0, 0.9 * 32767 / peak)  # about 1 dB of headroom for the edit
    save(ROOT / 'demo-audio-track.wav', array.array('h', (int(s * gain) for s in mix)))
    print(f'demo-audio-track.wav  {LENGTH:.0f}s')


if __name__ == '__main__':
    cmd, args = (sys.argv[1] if len(sys.argv) > 1 else ''), sys.argv[2:]
    if cmd in ('voiceover', 'all'):
        make_voiceover(set(args) if cmd == 'voiceover' else set())
    if cmd in ('prompts', 'all'):
        make_prompts()
    if cmd in ('track', 'all'):
        make_track()
    if cmd not in ('voiceover', 'prompts', 'track', 'all'):
        print(__doc__)
