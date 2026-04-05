"""Insert missing translation keys into app_string.dart for all locales after 'my'."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PATH = ROOT / "lib/utils/app_string.dart"
text = PATH.read_text(encoding="utf-8")
lines = text.splitlines(keepends=True)

# Locales to patch: (start_marker_line_contains, patches as list of (unique_anchor_substr, lines_to_insert_before_next_line))
# We insert AFTER the line that contains anchor_substr (first occurrence in that locale block).

LOCALE_PATCHES: dict[str, list[tuple[str, list[str]]]] = {}

# Build patches for fil, fr, de, gu, hi, id, it, ja, ko, ms, mr, fa, pl, pt, es, sv, ta, ur
# Each tuple: (anchor_after_which_we_insert, [new lines with newline])

def block(
    privacy_next: str,
    playlist_keys: tuple[str, str],
    media_line: str,
    feedback_extra: str,
    ab_lines: tuple[str, str, str],
    enter_new_extra: str,
    footer: list[str],
) -> list[tuple[str, list[str]]]:
    """privacy_next = full line after privacyPolicy for otherSettings insert."""
    pl1, pl2 = playlist_keys
    a1, a2, a3 = ab_lines
    return [
        (
            privacy_next.strip(),
            ["      'otherSettings': '%s',\n" % privacy_next.split("'otherSettings': '")[-1].split("',")[0] if False else ""],
        ),
    ]


# Manual data per locale (short)
DATA = {
    "fil": {
        "privacy": "      'privacyPolicy': 'Patakaran sa Privacy',\n",
        "other": "      'otherSettings': 'Iba pang mga Setting',\n",
        "playlist_after": "      'privacyPolicy': 'Patakaran sa Privacy',\n",
        "please_block_old": '      "pleaseSelectEnterPlaylistName":\n          "Mangyaring pumili o maglagay ng pangalan ng playlist",\n',
        "please_block_new": '      "pleaseSelectEnterPlaylistName":\n          "Mangyaring pumili o maglagay ng pangalan ng playlist",\n      "pleaseSelectOrCreate": "Mangyaring pumili o lumikha ng playlist",\n      "playlistNameAlreadyExists": "May playlist nang may ganitong pangalan",\n',
        "media_old": '      "mediaFile": "Media File",\n',
        "media_new": '      "mediaFile": "Media File",\n      "mediaFile:": "Media File",\n',
        "feedback_old": '      "hereIsMyFeedback:": "Narito ang aking feedback:",\n',
        "feedback_new": '      "hereIsMyFeedback": "Narito ang aking feedback:",\n      "hereIsMyFeedback:": "Narito ang aking feedback:",\n',
        "ab_old": '      "abCleared": "Na-clear na ang A-B Repeat",\n      "videoSettings":\n',
        "ab_new": '      "abCleared": "Na-clear na ang A-B Repeat",\n      "abSetPointA": "Itakda ang punto A",\n      "abSetPointB": "Itakda ang punto B",\n      "abClearRepeat": "I-clear ang A-B repeat",\n      "videoSettings":\n',
        "url_old": '      "enterNewName": "Ilagay ang bagong pangalan",\n      "videoRenamedSuccessfully":\n',
        "url_new": '      "enterNewName": "Ilagay ang bagong pangalan",\n      "pleaseEnterValidUrl": "Mangyaring maglagay ng wastong URL",\n      "videoRenamedSuccessfully":\n',
        "tail_old": '      "textScale": "Scale ng Teksto (%)",\n    },\n',
        "tail_new": '''      "textScale": "Scale ng Teksto (%)",
      "100": "100",
      "fileInformation": "Impormasyon ng file",
      "format": "Format",
      "created": "Nilikha",
      "retry": "Subukan muli",
      "albums": "Mga Album",
      "fileLocation": "Lokasyon ng file",
      "unknown": "Hindi alam",
    },
''',
    },
}

# Simpler approach: single text replace per locale using unique multi-line anchors from file

REPLACEMENTS: list[tuple[str, str]] = []

# fil
REPLACEMENTS.append(
    (
        "      'privacyPolicy': 'Patakaran sa Privacy',\n      \"playlist\":",
        "      'privacyPolicy': 'Patakaran sa Privacy',\n      'otherSettings': 'Iba pang mga Setting',\n      \"playlist\":",
    )
)
REPLACEMENTS.append(
    (
        '      "pleaseSelectEnterPlaylistName":\n          "Mangyaring pumili o maglagay ng pangalan ng playlist",\n      "alreadyExistIn":',
        '      "pleaseSelectEnterPlaylistName":\n          "Mangyaring pumili o maglagay ng pangalan ng playlist",\n      "pleaseSelectOrCreate": "Mangyaring pumili o lumikha ng playlist",\n      "playlistNameAlreadyExists": "May playlist nang may ganitong pangalan",\n      "alreadyExistIn":',
    )
)
REPLACEMENTS.append(
    (
        '      "mediaFile": "Media File",\n      "addedToFavourite": "Idinagdag sa Mga Paborito",\n',
        '      "mediaFile": "Media File",\n      "mediaFile:": "Media File",\n      "addedToFavourite": "Idinagdag sa Mga Paborito",\n',
    )
)
REPLACEMENTS.append(
    (
        '      "hereIsMyFeedback:": "Narito ang aking feedback:",\n      "checkOutThisAmazing":',
        '      "hereIsMyFeedback": "Narito ang aking feedback:",\n      "hereIsMyFeedback:": "Narito ang aking feedback:",\n      "checkOutThisAmazing":',
    )
)
REPLACEMENTS.append(
    (
        '      "abCleared": "Na-clear na ang A-B Repeat",\n      "videoSettings":\n          "Mga Setting ng Video",\n',
        '      "abCleared": "Na-clear na ang A-B Repeat",\n      "abSetPointA": "Itakda ang punto A",\n      "abSetPointB": "Itakda ang punto B",\n      "abClearRepeat": "I-clear ang A-B repeat",\n      "videoSettings":\n          "Mga Setting ng Video",\n',
    )
)
REPLACEMENTS.append(
    (
        '      "enterNewName": "Ilagay ang bagong pangalan",\n      "videoRenamedSuccessfully":\n          "Matagumpay na napalitan ang pangalan ng video!",\n',
        '      "enterNewName": "Ilagay ang bagong pangalan",\n      "pleaseEnterValidUrl": "Mangyaring maglagay ng wastong URL",\n      "videoRenamedSuccessfully":\n          "Matagumpay na napalitan ang pangalan ng video!",\n',
    )
)
REPLACEMENTS.append(
    (
        '      "textScale": "Scale ng Teksto (%)",\n    },\n    \'fr\': {\n',
        '''      "textScale": "Scale ng Teksto (%)",
      "100": "100",
      "fileInformation": "Impormasyon ng file",
      "format": "Format",
      "created": "Nilikha",
      "retry": "Subukan muli",
      "albums": "Mga Album",
      "fileLocation": "Lokasyon ng file",
      "unknown": "Hindi alam",
    },
    'fr': {
''',
    )
)

def main() -> None:
    s = PATH.read_text(encoding="utf-8")
    for old, new in REPLACEMENTS:
        if old not in s:
            raise SystemExit(f"Anchor not found:\n{old[:120]}...")
        s = s.replace(old, new, 1)
    PATH.write_text(s, encoding="utf-8")
    print("fil patched OK")

if __name__ == "__main__":
    main()
