# SubMiner + Anki (Lapis)

Japanese sentence mining: [SubMiner](https://docs.subminer.moe) drives mpv and
pushes cards into Anki over AnkiConnect using the **Lapis** note type.

`config.jsonc` here is the real config; `~/.config/SubMiner/config.jsonc` is a
symlink to it. SubMiner rewrites it with `JSON.stringify` on every UI change,
so comments in it are lost on the next save — notes belong here.

```sh
ln -s /path/to/dotfiles/SubMiner/config.jsonc ~/.config/SubMiner/config.jsonc
```

## Programs

| what | Gentoo |
|---|---|
| SubMiner (AppImage at `~/.local/bin/SubMiner.AppImage`) | — |
| bun (the `~/.local/bin/subminer` launcher) | `dev-lang/bun-bin` |
| mpv (IPC on `/tmp/subminer-socket`) | `media-video/mpv` |
| ffmpeg (card audio + screenshots) | `media-video/ffmpeg` |
| Anki | `app-misc/anki` |
| MeCab + dict (tokenizing, known-word highlighting) | `app-text/mecab app-dicts/mecab-ipadic` |
| yt-dlp | `net-misc/yt-dlp` |
| Noto CJK | `media-fonts/noto-cjk` |

## Anki, in this order

1. AnkiConnect add-on `2055492159`, restart Anki. Anki must run to mine.
2. `Lapis.apkg` from [donkuri/lapis](https://github.com/donkuri/lapis) → File
   → Import. Re-importing a newer apkg resets styling; copy CSS tweaks out first.
3. Create the deck in `ankiConnect.deck` (`日本語`).
4. Import a frequency and a pitch-accent dictionary into SubMiner's internal
   Yomitan, or `Frequency` / `FreqSort` / `PitchPosition` stay empty.

Yomitan needs no manual AnkiConnect setup: `ankiConnect.proxy.enabled` points
the internal profile at SubMiner's proxy on 8766, which forwards to 8765. A
browser Yomitan must use 8766 too, or AnkiConnect rejects its origin.

`"isLapis": { "enabled": true, "sentenceCardModel": "Lapis" }` — without it
Anki renders an empty front and creates nothing.

## Fields

`ankiConnect.fields`: `word`→`Expression`, `audio`→`ExpressionAudio`,
`image`→`Picture`, `sentence`→`Sentence`, `translation`→`SelectionText`,
`miscInfo`→`MiscInfo`. Sentence-card audio (`SentenceAudio`) and sentence are
hardcoded in `getEffectiveSentenceCardConfig()`.

## Keys

`Ctrl+S` mine · `Ctrl+Shift+S` mine selection · `Ctrl+V` update last card from
clipboard · `Ctrl+Shift+A` mark audio card · `Ctrl+G` field grouping ·
`Ctrl+Alt+S` subsync · `` ` `` stats · `Alt+Shift+O` toggle overlay. Rest in
`shortcuts` / `keybindings`.

## Checking

```sh
curl -s localhost:8765 -X POST -d '{"action":"version","version":6}'
curl -s localhost:8765 -X POST \
  -d '{"action":"modelFieldNames","version":6,"params":{"modelName":"Lapis"}}'
curl -s localhost:8765 -X POST -d '{"action":"canAddNotesWithErrorDetail","version":6,"params":{"notes":[
  {"deckName":"日本語","modelName":"Lapis",
   "fields":{"Sentence":"テスト文です。","Expression":"テスト文です。","IsSentenceCard":"x"},
   "tags":["SubMiner"]}]}}'
tail -f ~/.config/SubMiner/logs/app-$(date +%F).log
```

`logging.level` is `warn`; set `info` when debugging, and watch `[anki]`.
