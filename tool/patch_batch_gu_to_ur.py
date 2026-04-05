# -*- coding: utf-8 -*-
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / "lib/utils/app_string.dart"

PATCHES: list[tuple[str, str]] = [
    # Gujarati
    (
        "      'privacyPolicy': 'પ્રાઇવસી પોલિસી',\n      \"playlist\": \"પ્લેલિસ્ટ\",",
        "      'privacyPolicy': 'પ્રાઇવસી પોલિસી',\n      'otherSettings': 'અન્ય સેટિંગ્સ',\n      \"playlist\": \"પ્લેલિસ્ટ\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "કૃપા કરીને પ્લેલિસ્ટનું નામ પસંદ કરો અથવા લખો",\n      "alreadyExistIn": "પહેલેથી જ આમાં છે:",',
        '      "pleaseSelectEnterPlaylistName":\n          "કૃપા કરીને પ્લેલિસ્ટનું નામ પસંદ કરો અથવા લખો",\n      "pleaseSelectOrCreate": "કૃપા કરીને પ્લેલિસ્ટ પસંદ કરો અથવા નવી બનાવો",\n      "playlistNameAlreadyExists": "આ નામની પ્લેલિસ્ટ પહેલેથી જ છે",\n      "alreadyExistIn": "પહેલેથી જ આમાં છે:",',
    ),
    (
        '      "mediaFile": "મીડિયા ફાઇલ",\n      "addedToFavourite": "ફેવરિટમાં ઉમેરવામાં આવ્યું",\n',
        '      "mediaFile": "મીડિયા ફાઇલ",\n      "mediaFile:": "મીડિયા ફાઇલ",\n      "addedToFavourite": "ફેવરિટમાં ઉમેરવામાં આવ્યું",\n',
    ),
    (
        '      "hereIsMyFeedback:": "અહીં મારો પ્રતિસાદ છે:",\n      "checkOutThisAmazing": "આ અદ્ભુત વીડિયો અને મ્યુઝિક પ્લેયર એપ જુઓ!",',
        '      "hereIsMyFeedback": "અહીં મારો પ્રતિસાદ છે:",\n      "hereIsMyFeedback:": "અહીં મારો પ્રતિસાદ છે:",\n      "checkOutThisAmazing": "આ અદ્ભુત વીડિયો અને મ્યુઝિક પ્લેયર એપ જુઓ!",',
    ),
    (
        '      "abCleared": "A-B રિપીટ ક્લિયર થયું",\n      "videoSettings": "વિડિયો સેટિંગ્સ",\n',
        '      "abCleared": "A-B રિપીટ ક્લિયર થયું",\n      "abSetPointA": "પોઈન્ટ A સેટ કરો",\n      "abSetPointB": "પોઈન્ટ B સેટ કરો",\n      "abClearRepeat": "A-B રિપીટ સાફ કરો",\n      "videoSettings": "વિડિયો સેટિંગ્સ",\n',
    ),
    (
        '      "enterNewName": "નવું નામ દાખલ કરો",\n      "videoRenamedSuccessfully": "વિડિયોનું નામ સફળતાપૂર્વક બદલાઈ ગયું!",\n',
        '      "enterNewName": "નવું નામ દાખલ કરો",\n      "pleaseEnterValidUrl": "કૃપા કરીને માન્ય URL દાખલ કરો",\n      "videoRenamedSuccessfully": "વિડિયોનું નામ સફળતાપૂર્વક બદલાઈ ગયું!",\n',
    ),
    (
        '      "textScale": "ટેક્સ્ટ સ્કેલ (%)",\n    },\n    \'hi\': {\n',
        '''      "textScale": "ટેક્સ્ટ સ્કેલ (%)",
      "100": "100",
      "fileInformation": "ફાઇલ માહિતી",
      "format": "ફોર્મેટ",
      "created": "બનાવ્યાની તારીખ",
      "retry": "ફરી પ્રયાસ કરો",
      "albums": "આલ્બમ્સ",
      "fileLocation": "ફાઇલ સ્થાન",
    },
    'hi': {
''',
    ),
]

def main() -> None:
    s = PATH.read_text(encoding="utf-8")
    for i, (old, new) in enumerate(PATCHES):
        if old not in s:
            raise SystemExit(f"Patch {i} not found:\n{old[:180]}")
        s = s.replace(old, new, 1)
    PATH.write_text(s, encoding="utf-8")
    print("gu OK", len(PATCHES))

if __name__ == "__main__":
    main()
