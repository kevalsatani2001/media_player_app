# -*- coding: utf-8 -*-
from pathlib import Path

P = Path(__file__).resolve().parent.parent / "lib/utils/app_string.dart"
PATCHES: list[tuple[str, str]] = [
    (
        "      'privacyPolicy': 'プライバシーポリシー',\n      \"playlist\": \"プレイリスト\",",
        "      'privacyPolicy': 'プライバシーポリシー',\n      'otherSettings': 'その他の設定',\n      \"playlist\": \"プレイリスト\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName": "プレイリスト名を選択または入力してください",\n      "alreadyExistIn": "既に存在します：",',
        '      "pleaseSelectEnterPlaylistName": "プレイリスト名を選択または入力してください",\n      "pleaseSelectOrCreate": "プレイリストを選択または新規作成してください",\n      "playlistNameAlreadyExists": "この名前のプレイリストは既に存在します",\n      "alreadyExistIn": "既に存在します：",',
    ),
    (
        '      "mediaFile": "メディアファイル",\n      "addedToFavourite": "お気に入りに追加されました",\n',
        '      "mediaFile": "メディアファイル",\n      "mediaFile:": "メディアファイル",\n      "addedToFavourite": "お気に入りに追加されました",\n',
    ),
    (
        '      "hereIsMyFeedback:": "こちらが私のフィードバックです：",\n      "checkOutThisAmazing": "この素晴らしいビデオ＆音楽プレーヤーアプリをチェックしてください！",',
        '      "hereIsMyFeedback": "こちらが私のフィードバックです：",\n      "hereIsMyFeedback:": "こちらが私のフィードバックです：",\n      "checkOutThisAmazing": "この素晴らしいビデオ＆音楽プレーヤーアプリをチェックしてください！",',
    ),
    (
        '      "abCleared": "A-B間リピートを解除しました",\n      "videoSettings": "動画設定",\n',
        '      "abCleared": "A-B間リピートを解除しました",\n      "abSetPointA": "地点Aを設定",\n      "abSetPointB": "地点Bを設定",\n      "abClearRepeat": "A-Bリピートをクリア",\n      "videoSettings": "動画設定",\n',
    ),
    (
        '      "enterNewName": "新しい名前を入力してください",\n      "videoRenamedSuccessfully": "動画名を変更しました！",\n',
        '      "enterNewName": "新しい名前を入力してください",\n      "pleaseEnterValidUrl": "有効なURLを入力してください",\n      "videoRenamedSuccessfully": "動画名を変更しました！",\n',
    ),
    (
        '      "textScale": "テキスト倍率 (%)",\n    },\n    \'ko\': {\n',
        '''      "textScale": "テキスト倍率 (%)",
      "100": "100",
      "fileInformation": "ファイル情報",
      "format": "形式",
      "created": "作成日",
      "retry": "再試行",
      "albums": "アルバム",
      "fileLocation": "ファイルの場所",
    },
    'ko': {
''',
    ),
    (
        "      'privacyPolicy': '개인정보 처리방침',\n      \"playlist\": \"재생목록\",",
        "      'privacyPolicy': '개인정보 처리방침',\n      'otherSettings': '기타 설정',\n      \"playlist\": \"재생목록\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName": "재생목록 이름을 선택하거나 입력하세요",\n      "alreadyExistIn": "이미 다음에 존재함:",',
        '      "pleaseSelectEnterPlaylistName": "재생목록 이름을 선택하거나 입력하세요",\n      "pleaseSelectOrCreate": "재생목록을 선택하거나 새로 만드세요",\n      "playlistNameAlreadyExists": "이 이름의 재생목록이 이미 있습니다",\n      "alreadyExistIn": "이미 다음에 존재함:",',
    ),
    (
        '      "mediaFile": "미디어 파일",\n      "addedToFavourite": "즐겨찾기에 추가됨",\n',
        '      "mediaFile": "미디어 파일",\n      "mediaFile:": "미디어 파일",\n      "addedToFavourite": "즐겨찾기에 추가됨",\n',
    ),
    (
        '      "hereIsMyFeedback:": "제 피드백입니다:",\n      "checkOutThisAmazing": "이 놀라운 비디오 및 음악 플레이어 앱을 확인해 보세요!",',
        '      "hereIsMyFeedback": "제 피드백입니다:",\n      "hereIsMyFeedback:": "제 피드백입니다:",\n      "checkOutThisAmazing": "이 놀라운 비디오 및 음악 플레이어 앱을 확인해 보세요!",',
    ),
    (
        '      "abCleared": "A-B 반복 해제됨",\n      "videoSettings": "비디오 설정",\n',
        '      "abCleared": "A-B 반복 해제됨",\n      "abSetPointA": "A 지점 설정",\n      "abSetPointB": "B 지점 설정",\n      "abClearRepeat": "A-B 반복 지우기",\n      "videoSettings": "비디오 설정",\n',
    ),
    (
        '      "enterNewName": "새 이름 입력",\n      "videoRenamedSuccessfully": "비디오 이름이 변경되었습니다!",\n',
        '      "enterNewName": "새 이름 입력",\n      "pleaseEnterValidUrl": "유효한 URL을 입력하세요",\n      "videoRenamedSuccessfully": "비디오 이름이 변경되었습니다!",\n',
    ),
    (
        '      "textScale": "텍스트 배율 (%)",\n    },\n    \'ms\': {\n',
        '''      "textScale": "텍스트 배율 (%)",
      "100": "100",
      "fileInformation": "파일 정보",
      "format": "형식",
      "created": "만든 날짜",
      "retry": "다시 시도",
      "albums": "앨범",
      "fileLocation": "파일 위치",
    },
    'ms': {
''',
    ),
]


def main() -> None:
    s = P.read_text(encoding="utf-8")
    for i, (o, n) in enumerate(PATCHES):
        if o not in s:
            raise SystemExit(f"fail {i}: {o[:100]}")
        s = s.replace(o, n, 1)
    P.write_text(s, encoding="utf-8")
    print("ok", len(PATCHES))


if __name__ == "__main__":
    main()
