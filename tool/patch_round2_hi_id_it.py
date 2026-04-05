# -*- coding: utf-8 -*-
from pathlib import Path

P = Path(__file__).resolve().parent.parent / "lib/utils/app_string.dart"

PATCHES: list[tuple[str, str]] = [
    # Hindi
    (
        "      'privacyPolicy': 'गोपनीयता नीति',\n      \"playlist\": \"प्लेलिस्ट\",",
        "      'privacyPolicy': 'गोपनीयता नीति',\n      'otherSettings': 'अन्य सेटिंग्स',\n      \"playlist\": \"प्लेलिस्ट\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "कृपया प्लेलिस्ट का नाम चुनें या दर्ज करें",\n      "alreadyExistIn": "पहले से ही इसमें मौजूद है:",',
        '      "pleaseSelectEnterPlaylistName":\n          "कृपया प्लेलिस्ट का नाम चुनें या दर्ज करें",\n      "pleaseSelectOrCreate": "कृपया प्लेलिस्ट चुनें या नई बनाएँ",\n      "playlistNameAlreadyExists": "इस नाम की प्लेलिस्ट पहले से मौजूद है",\n      "alreadyExistIn": "पहले से ही इसमें मौजूद है:",',
    ),
    (
        '      "mediaFile": "मीडिया फ़ाइल",\n      "addedToFavourite": "पसंदीदा में जोड़ा गया",\n',
        '      "mediaFile": "मीडिया फ़ाइल",\n      "mediaFile:": "मीडिया फ़ाइल",\n      "addedToFavourite": "पसंदीदा में जोड़ा गया",\n',
    ),
    (
        '      "hereIsMyFeedback:": "यहाँ मेरा फीडबैक है:",\n      "checkOutThisAmazing": "इस अद्भुत वीडियो और संगीत प्लेयर ऐप को देखें!",',
        '      "hereIsMyFeedback": "यहाँ मेरा फीडबैक है:",\n      "hereIsMyFeedback:": "यहाँ मेरा फीडबैक है:",\n      "checkOutThisAmazing": "इस अद्भुत वीडियो और संगीत प्लेयर ऐप को देखें!",',
    ),
    (
        '      "abCleared": "A-B रिपीट हटा दिया गया",\n      "videoSettings": "वीडियो सेटिंग्स",\n',
        '      "abCleared": "A-B रिपीट हटा दिया गया",\n      "abSetPointA": "पॉइंट A सेट करें",\n      "abSetPointB": "पॉइंट B सेट करें",\n      "abClearRepeat": "A-B रिपीट साफ़ करें",\n      "videoSettings": "वीडियो सेटिंग्स",\n',
    ),
    (
        '      "enterNewName": "नया नाम डालें",\n      "videoRenamedSuccessfully": "वीडियो का नाम सफलतापूर्वक बदला गया!",\n',
        '      "enterNewName": "नया नाम डालें",\n      "pleaseEnterValidUrl": "कृपया मान्य URL दर्ज करें",\n      "videoRenamedSuccessfully": "वीडियो का नाम सफलतापूर्वक बदला गया!",\n',
    ),
    (
        '      "textScale": "टेक्स्ट स्केल (%)",\n    },\n    \'id\': {\n',
        '''      "textScale": "टेक्स्ट स्केल (%)",
      "100": "100",
      "fileInformation": "फ़ाइल जानकारी",
      "format": "फ़ॉर्मेट",
      "created": "बनाया गया",
      "retry": "पुनः प्रयास करें",
      "albums": "एल्बम",
      "fileLocation": "फ़ाइल स्थान",
    },
    'id': {
''',
    ),
    # Indonesian
    (
        "      'privacyPolicy': 'Kebijakan Privasi',\n      \"playlist\": \"Daftar putar\",",
        "      'privacyPolicy': 'Kebijakan Privasi',\n      'otherSettings': 'Pengaturan lain',\n      \"playlist\": \"Daftar putar\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "Silakan pilih atau masukkan nama daftar putar",\n      "alreadyExistIn": "Sudah ada di",',
        '      "pleaseSelectEnterPlaylistName":\n          "Silakan pilih atau masukkan nama daftar putar",\n      "pleaseSelectOrCreate": "Pilih atau buat daftar putar",\n      "playlistNameAlreadyExists": "Daftar putar dengan nama ini sudah ada",\n      "alreadyExistIn": "Sudah ada di",',
    ),
    (
        '      "mediaFile": "Berkas Media",\n      "addedToFavourite": "Ditambahkan ke Favorit",\n',
        '      "mediaFile": "Berkas Media",\n      "mediaFile:": "Berkas Media",\n      "addedToFavourite": "Ditambahkan ke Favorit",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Berikut adalah umpan balik saya:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Berikut adalah umpan balik saya:",\n      "hereIsMyFeedback:": "Berikut adalah umpan balik saya:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "Pengulangan A-B dihapus",\n      "videoSettings": "Pengaturan Video",\n',
        '      "abCleared": "Pengulangan A-B dihapus",\n      "abSetPointA": "Atur titik A",\n      "abSetPointB": "Atur titik B",\n      "abClearRepeat": "Hapus ulang A-B",\n      "videoSettings": "Pengaturan Video",\n',
    ),
    (
        '      "enterNewName": "Masukkan nama baru",\n      "videoRenamedSuccessfully": "Video berhasil diganti namanya!",\n',
        '      "enterNewName": "Masukkan nama baru",\n      "pleaseEnterValidUrl": "Masukkan URL yang valid",\n      "videoRenamedSuccessfully": "Video berhasil diganti namanya!",\n',
    ),
    (
        '      "textScale": "Skala Teks (%)",\n    },\n    \'it\': {\n',
        '''      "textScale": "Skala Teks (%)",
      "100": "100",
      "fileInformation": "Informasi file",
      "format": "Format",
      "created": "Dibuat",
      "retry": "Coba lagi",
      "albums": "Album",
      "fileLocation": "Lokasi file",
    },
    'it': {
''',
    ),
    # Italian
    (
        "      'privacyPolicy': 'Informativa sulla privacy',\n      \"playlist\": \"Playlist\",",
        "      'privacyPolicy': 'Informativa sulla privacy',\n      'otherSettings': 'Altre impostazioni',\n      \"playlist\": \"Playlist\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "Seleziona o inserisci il nome della playlist",\n      "alreadyExistIn": "Esiste già in",',
        '      "pleaseSelectEnterPlaylistName":\n          "Seleziona o inserisci il nome della playlist",\n      "pleaseSelectOrCreate": "Seleziona o crea una playlist",\n      "playlistNameAlreadyExists": "Esiste già una playlist con questo nome",\n      "alreadyExistIn": "Esiste già in",',
    ),
    (
        '      "mediaFile": "File Multimediale",\n      "addedToFavourite": "Aggiunto ai Preferiti",\n',
        '      "mediaFile": "File Multimediale",\n      "mediaFile:": "File Multimediale",\n      "addedToFavourite": "Aggiunto ai Preferiti",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Ecco il mio feedback:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Ecco il mio feedback:",\n      "hereIsMyFeedback:": "Ecco il mio feedback:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "Ripetizione A-B rimossa",\n      "videoSettings": "Impostazioni video",\n',
        '      "abCleared": "Ripetizione A-B rimossa",\n      "abSetPointA": "Imposta punto A",\n      "abSetPointB": "Imposta punto B",\n      "abClearRepeat": "Cancella ripetizione A-B",\n      "videoSettings": "Impostazioni video",\n',
    ),
    (
        '      "enterNewName": "Inserisci nuovo nome",\n      "videoRenamedSuccessfully": "Video rinominato con successo!",\n',
        '      "enterNewName": "Inserisci nuovo nome",\n      "pleaseEnterValidUrl": "Inserisci un URL valido",\n      "videoRenamedSuccessfully": "Video rinominato con successo!",\n',
    ),
    (
        '      "textScale": "Scala testo (%)",\n    },\n    \'ja\': {\n',
        '''      "textScale": "Scala testo (%)",
      "100": "100",
      "fileInformation": "Informazioni file",
      "format": "Formato",
      "created": "Creato",
      "retry": "Riprova",
      "albums": "Album",
      "fileLocation": "Posizione file",
    },
    'ja': {
''',
    ),
]


def main() -> None:
    s = P.read_text(encoding="utf-8")
    for i, (o, n) in enumerate(PATCHES):
        if o not in s:
            raise SystemExit(f"Fail {i}:\n{o[:160]}")
        s = s.replace(o, n, 1)
    P.write_text(s, encoding="utf-8")
    print("patched", len(PATCHES))


if __name__ == "__main__":
    main()
