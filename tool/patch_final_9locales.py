# -*- coding: utf-8 -*-
"""Last batch: ms, mr, fa, pl, pt, es, sv, ta, ur — missing playlist/AB/footer keys."""
from pathlib import Path

P = Path(__file__).resolve().parent.parent / "lib/utils/app_string.dart"

PATCHES: list[tuple[str, str]] = [
    # ms
    (
        "      'privacyPolicy': 'Dasar Privasi',\n      \"playlist\": \"Senarai main\",",
        "      'privacyPolicy': 'Dasar Privasi',\n      'otherSettings': 'Tetapan lain',\n      \"playlist\": \"Senarai main\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "Sila pilih atau masukkan nama senarai main",\n      "alreadyExistIn": "Sudah wujud dalam",',
        '      "pleaseSelectEnterPlaylistName":\n          "Sila pilih atau masukkan nama senarai main",\n      "pleaseSelectOrCreate": "Pilih atau cipta senarai main",\n      "playlistNameAlreadyExists": "Senarai main dengan nama ini sudah wujud",\n      "alreadyExistIn": "Sudah wujud dalam",',
    ),
    (
        '      "mediaFile": "Fail Media",\n      "addedToFavourite": "Ditambah ke Kegemaran",\n',
        '      "mediaFile": "Fail Media",\n      "mediaFile:": "Fail Media",\n      "addedToFavourite": "Ditambah ke Kegemaran",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Berikut adalah maklum balas saya:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Berikut adalah maklum balas saya:",\n      "hereIsMyFeedback:": "Berikut adalah maklum balas saya:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "Ulang A-B dikosongkan",\n      "videoSettings": "Tetapan Video",\n',
        '      "abCleared": "Ulang A-B dikosongkan",\n      "abSetPointA": "Tetapkan titik A",\n      "abSetPointB": "Tetapkan titik B",\n      "abClearRepeat": "Kosongkan ulang A-B",\n      "videoSettings": "Tetapan Video",\n',
    ),
    (
        '      "enterNewName": "Masukkan nama baru",\n      "videoRenamedSuccessfully": "Video berjaya dinamakan semula!",\n',
        '      "enterNewName": "Masukkan nama baru",\n      "pleaseEnterValidUrl": "Sila masukkan URL yang sah",\n      "videoRenamedSuccessfully": "Video berjaya dinamakan semula!",\n',
    ),
    (
        '      "textScale": "Skala Teks (%)",\n    },\n    \'mr\': {\n',
        '''      "textScale": "Skala Teks (%)",
      "100": "100",
      "fileInformation": "Maklumat fail",
      "format": "Format",
      "created": "Dicipta",
      "retry": "Cuba lagi",
      "albums": "Album",
      "fileLocation": "Lokasi fail",
    },
    'mr': {
''',
    ),
    # mr
    (
        "      'privacyPolicy': 'गोपनीयता धोरण',\n      \"playlist\": \"प्लेलिस्ट\",",
        "      'privacyPolicy': 'गोपनीयता धोरण',\n      'otherSettings': 'इतर सेटिंग्ज',\n      \"playlist\": \"प्लेलिस्ट\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "कृपया प्लेलिस्टचे नाव निवडा किंवा प्रविष्ट करा",\n      "alreadyExistIn": "आधीच यामध्ये आहे:",',
        '      "pleaseSelectEnterPlaylistName":\n          "कृपया प्लेलिस्टचे नाव निवडा किंवा प्रविष्ट करा",\n      "pleaseSelectOrCreate": "प्लेलिस्ट निवडा किंवा नवीन तयार करा",\n      "playlistNameAlreadyExists": "या नावाची प्लेलिस्ट आधीच अस्तित्वात आहे",\n      "alreadyExistIn": "आधीच यामध्ये आहे:",',
    ),
    (
        '      "mediaFile": "मीडिया फाइल",\n      "addedToFavourite": "पसंतीमध्ये जोडले",\n',
        '      "mediaFile": "मीडिया फाइल",\n      "mediaFile:": "मीडिया फाइल",\n      "addedToFavourite": "पसंतीमध्ये जोडले",\n',
    ),
    (
        '      "hereIsMyFeedback:": "येथे माझा अभिप्राय आहे:",\n      "checkOutThisAmazing": "हे आश्चर्यकारक व्हिडिओ आणि संगीत प्लेयर अॅप पहा!",',
        '      "hereIsMyFeedback": "येथे माझा अभिप्राय आहे:",\n      "hereIsMyFeedback:": "येथे माझा अभिप्राय आहे:",\n      "checkOutThisAmazing": "हे आश्चर्यकारक व्हिडिओ आणि संगीत प्लेयर अॅप पहा!",',
    ),
    (
        '      "abCleared": "A-B रिपीट क्लिअर झाले",\n      "videoSettings": "व्हिडिओ सेटिंग्ज",\n',
        '      "abCleared": "A-B रिपीट क्लिअर झाले",\n      "abSetPointA": "पॉइंट A सेट करा",\n      "abSetPointB": "पॉइंट B सेट करा",\n      "abClearRepeat": "A-B रिपीट साफ करा",\n      "videoSettings": "व्हिडिओ सेटिंग्ज",\n',
    ),
    (
        '      "enterNewName": "नवीन नाव टाका",\n      "videoRenamedSuccessfully": "व्हिडिओचे नाव यशस्वीपणे बदलले!",\n',
        '      "enterNewName": "नवीन नाव टाका",\n      "pleaseEnterValidUrl": "कृपया वैध URL टाका",\n      "videoRenamedSuccessfully": "व्हिडिओचे नाव यशस्वीपणे बदलले!",\n',
    ),
    (
        '      "textScale": "टेक्स्ट स्केल (%)",\n    },\n    \'fa\': {\n',
        '''      "textScale": "टेक्स्ट स्केल (%)",
      "100": "100",
      "fileInformation": "फाइल माहिती",
      "format": "फॉरमॅट",
      "created": "तयार केले",
      "retry": "पुन्हा प्रयत्न करा",
      "albums": "अल्बम",
      "fileLocation": "फाइल स्थान",
    },
    'fa': {
''',
    ),
    # fa
    (
        "      'privacyPolicy': 'سیاست حریم خصوصی',\n      \"playlist\": \"لیست پخش\",",
        "      'privacyPolicy': 'سیاست حریم خصوصی',\n      'otherSettings': 'سایر تنظیمات',\n      \"playlist\": \"لیست پخش\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "لطفاً نام لیست پخش را انتخاب یا وارد کنید",\n      "alreadyExistIn": "از قبل موجود است در",',
        '      "pleaseSelectEnterPlaylistName":\n          "لطفاً نام لیست پخش را انتخاب یا وارد کنید",\n      "pleaseSelectOrCreate": "لیست پخش را انتخاب یا جدید بسازید",\n      "playlistNameAlreadyExists": "لیست پخشی با این نام از قبل وجود دارد",\n      "alreadyExistIn": "از قبل موجود است در",',
    ),
    (
        '      "mediaFile": "فایل رسانه‌ای",\n      "addedToFavourite": "به علاقه‌مندی‌ها اضافه شد",\n',
        '      "mediaFile": "فایل رسانه‌ای",\n      "mediaFile:": "فایل رسانه‌ای",\n      "addedToFavourite": "به علاقه‌مندی‌ها اضافه شد",\n',
    ),
    (
        '      "hereIsMyFeedback:": "این بازخورد من است:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "این بازخورد من است:",\n      "hereIsMyFeedback:": "این بازخورد من است:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "تکرار A-B پاک شد",\n      "videoSettings": "تنظیمات ویدیو",\n',
        '      "abCleared": "تکرار A-B پاک شد",\n      "abSetPointA": "تنظیم نقطه A",\n      "abSetPointB": "تنظیم نقطه B",\n      "abClearRepeat": "پاک کردن تکرار A-B",\n      "videoSettings": "تنظیمات ویدیو",\n',
    ),
    (
        '      "enterNewName": "نام جدید را وارد کنید",\n      "videoRenamedSuccessfully": "نام ویدیو با موفقیت تغییر کرد!",\n',
        '      "enterNewName": "نام جدید را وارد کنید",\n      "pleaseEnterValidUrl": "لطفاً یک URL معتبر وارد کنید",\n      "videoRenamedSuccessfully": "نام ویدیو با موفقیت تغییر کرد!",\n',
    ),
    (
        '      "textScale": "مقیاس متن (%)",\n    },\n    \'pl\': {\n',
        '''      "textScale": "مقیاس متن (%)",
      "100": "100",
      "fileInformation": "اطلاعات فایل",
      "format": "فرمت",
      "created": "ایجاد شده",
      "retry": "تلاش مجدد",
      "albums": "آلبوم‌ها",
      "fileLocation": "محل فایل",
    },
    'pl': {
''',
    ),
    # pl
    (
        "      'privacyPolicy': 'Polityka prywatności',\n      \"playlist\": \"Playlista\",",
        "      'privacyPolicy': 'Polityka prywatności',\n      'otherSettings': 'Inne ustawienia',\n      \"playlist\": \"Playlista\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName": "Wybierz lub wprowadź nazwę playlisty",\n      "alreadyExistIn": "Już istnieje w",',
        '      "pleaseSelectEnterPlaylistName": "Wybierz lub wprowadź nazwę playlisty",\n      "pleaseSelectOrCreate": "Wybierz playlistę lub utwórz nową",\n      "playlistNameAlreadyExists": "Playlista o tej nazwie już istnieje",\n      "alreadyExistIn": "Już istnieje w",',
    ),
    (
        '      "mediaFile": "Plik multimedialny",\n      "addedToFavourite": "Dodano do ulubionych",\n',
        '      "mediaFile": "Plik multimedialny",\n      "mediaFile:": "Plik multimedialny",\n      "addedToFavourite": "Dodano do ulubionych",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Oto moja opinia:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Oto moja opinia:",\n      "hereIsMyFeedback:": "Oto moja opinia:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "Powtarzanie A-B wyczyszczone",\n      "videoSettings": "Ustawienia wideo",\n',
        '      "abCleared": "Powtarzanie A-B wyczyszczone",\n      "abSetPointA": "Ustaw punkt A",\n      "abSetPointB": "Ustaw punkt B",\n      "abClearRepeat": "Wyczyść powtarzanie A-B",\n      "videoSettings": "Ustawienia wideo",\n',
    ),
    (
        '      "enterNewName": "Wprowadź nową nazwę",\n      "videoRenamedSuccessfully": "Pomyślnie zmieniono nazwę!",\n',
        '      "enterNewName": "Wprowadź nową nazwę",\n      "pleaseEnterValidUrl": "Wprowadź prawidłowy adres URL",\n      "videoRenamedSuccessfully": "Pomyślnie zmieniono nazwę!",\n',
    ),
    (
        '      "textScale": "Skala tekstu (%)",\n    },\n    \'pt\': {\n',
        '''      "textScale": "Skala tekstu (%)",
      "100": "100",
      "fileInformation": "Informacje o pliku",
      "format": "Format",
      "created": "Utworzono",
      "retry": "Spróbuj ponownie",
      "albums": "Albumy",
      "fileLocation": "Lokalizacja pliku",
    },
    'pt': {
''',
    ),
    # pt
    (
        "      'privacyPolicy': 'Política de Privacidade',\n      \"playlist\": \"Lista de reprodução\",",
        "      'privacyPolicy': 'Política de Privacidade',\n      'otherSettings': 'Outras definições',\n      \"playlist\": \"Lista de reprodução\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "Por favor, selecione ou insira o nome da playlist",\n      "alreadyExistIn": "Já existe em",',
        '      "pleaseSelectEnterPlaylistName":\n          "Por favor, selecione ou insira o nome da playlist",\n      "pleaseSelectOrCreate": "Selecione ou crie uma lista de reprodução",\n      "playlistNameAlreadyExists": "Já existe uma lista com este nome",\n      "alreadyExistIn": "Já existe em",',
    ),
    (
        '      "mediaFile": "Arquivo de Mídia",\n      "addedToFavourite": "Adicionado aos Favoritos",\n',
        '      "mediaFile": "Arquivo de Mídia",\n      "mediaFile:": "Arquivo de Mídia",\n      "addedToFavourite": "Adicionado aos Favoritos",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Aqui está o meu feedback:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Aqui está o meu feedback:",\n      "hereIsMyFeedback:": "Aqui está o meu feedback:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "Repetição A-B limpa",\n      "videoSettings": "Configurações de vídeo",\n',
        '      "abCleared": "Repetição A-B limpa",\n      "abSetPointA": "Definir ponto A",\n      "abSetPointB": "Definir ponto B",\n      "abClearRepeat": "Limpar repetição A-B",\n      "videoSettings": "Configurações de vídeo",\n',
    ),
    (
        '      "enterNewName": "Insira o novo nome",\n      "videoRenamedSuccessfully": "Vídeo renomeado com sucesso!",\n',
        '      "enterNewName": "Insira o novo nome",\n      "pleaseEnterValidUrl": "Insira um URL válido",\n      "videoRenamedSuccessfully": "Vídeo renomeado com sucesso!",\n',
    ),
    (
        '      "textScale": "Escala do texto (%)",\n    },\n    \'es\': {\n',
        '''      "textScale": "Escala do texto (%)",
      "100": "100",
      "fileInformation": "Informações do ficheiro",
      "format": "Formato",
      "created": "Criado",
      "retry": "Tentar novamente",
      "albums": "Álbuns",
      "fileLocation": "Localização do ficheiro",
    },
    'es': {
''',
    ),
    # es
    (
        "      'privacyPolicy': 'Política de privacidad',\n      \"playlist\": \"Lista de reproducción\",",
        "      'privacyPolicy': 'Política de privacidad',\n      'otherSettings': 'Otros ajustes',\n      \"playlist\": \"Lista de reproducción\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "Por favor seleccione o ingrese un nombre",\n      "alreadyExistIn": "Ya existe en",',
        '      "pleaseSelectEnterPlaylistName":\n          "Por favor seleccione o ingrese un nombre",\n      "pleaseSelectOrCreate": "Seleccione o cree una lista de reproducción",\n      "playlistNameAlreadyExists": "Ya existe una lista con este nombre",\n      "alreadyExistIn": "Ya existe en",',
    ),
    (
        '      "mediaFile": "Archivo multimedia",\n      "addedToFavourite": "Agregado a favoritos",\n',
        '      "mediaFile": "Archivo multimedia",\n      "mediaFile:": "Archivo multimedia",\n      "addedToFavourite": "Agregado a favoritos",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Aquí están mis comentarios:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Aquí están mis comentarios:",\n      "hereIsMyFeedback:": "Aquí están mis comentarios:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "Repetición A-B cancelada",\n      "videoSettings": "Ajustes de video",\n',
        '      "abCleared": "Repetición A-B cancelada",\n      "abSetPointA": "Establecer punto A",\n      "abSetPointB": "Establecer punto B",\n      "abClearRepeat": "Borrar repetición A-B",\n      "videoSettings": "Ajustes de video",\n',
    ),
    (
        '      "enterNewName": "Introduce el nuevo nombre",\n      "videoRenamedSuccessfully": "¡Video renombrado con éxito!",\n',
        '      "enterNewName": "Introduce el nuevo nombre",\n      "pleaseEnterValidUrl": "Introduce una URL válida",\n      "videoRenamedSuccessfully": "¡Video renombrado con éxito!",\n',
    ),
    (
        '      "textScale": "Escala de texto (%)",\n    },\n    \'sv\': {\n',
        '''      "textScale": "Escala de texto (%)",
      "100": "100",
      "fileInformation": "Información del archivo",
      "format": "Formato",
      "created": "Creado",
      "retry": "Reintentar",
      "albums": "Álbumes",
      "fileLocation": "Ubicación del archivo",
    },
    'sv': {
''',
    ),
    # sv
    (
        "      'privacyPolicy': 'Integritetspolicy',\n      \"playlist\": \"Spellista\",",
        "      'privacyPolicy': 'Integritetspolicy',\n      'otherSettings': 'Övriga inställningar',\n      \"playlist\": \"Spellista\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName": "Välj eller ange spellistans namn",\n      "alreadyExistIn": "Finns redan i",',
        '      "pleaseSelectEnterPlaylistName": "Välj eller ange spellistans namn",\n      "pleaseSelectOrCreate": "Välj eller skapa en spellista",\n      "playlistNameAlreadyExists": "En spellista med detta namn finns redan",\n      "alreadyExistIn": "Finns redan i",',
    ),
    (
        '      "mediaFile": "Mediafil",\n      "addedToFavourite": "Tillagd i favoriter",\n',
        '      "mediaFile": "Mediafil",\n      "mediaFile:": "Mediafil",\n      "addedToFavourite": "Tillagd i favoriter",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Här är min feedback:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Här är min feedback:",\n      "hereIsMyFeedback:": "Här är min feedback:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "A-B-upprepning rensad",\n      "videoSettings": "Videoinställningar",\n',
        '      "abCleared": "A-B-upprepning rensad",\n      "abSetPointA": "Ange punkt A",\n      "abSetPointB": "Ange punkt B",\n      "abClearRepeat": "Rensa A-B-upprepning",\n      "videoSettings": "Videoinställningar",\n',
    ),
    (
        '      "enterNewName": "Ange nytt namn",\n      "videoRenamedSuccessfully": "Videon har bytt namn!",\n',
        '      "enterNewName": "Ange nytt namn",\n      "pleaseEnterValidUrl": "Ange en giltig URL",\n      "videoRenamedSuccessfully": "Videon har bytt namn!",\n',
    ),
    (
        '      "textScale": "Textskala (%)",\n    },\n    \'ta\': {\n',
        '''      "textScale": "Textskala (%)",
      "100": "100",
      "fileInformation": "Filinformation",
      "format": "Format",
      "created": "Skapad",
      "retry": "Försök igen",
      "albums": "Album",
      "fileLocation": "Filplats",
    },
    'ta': {
''',
    ),
    # ta
    (
        "      'privacyPolicy': 'தனியுரிமைக் கொள்கை',\n      \"playlist\": \"பிளேலிஸ்ட்\",",
        "      'privacyPolicy': 'தனியுரிமைக் கொள்கை',\n      'otherSettings': 'பிற அமைப்புகள்',\n      \"playlist\": \"பிளேலிஸ்ட்\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "பிளேலிஸ்ட் பெயரைத் தேர்ந்தெடுக்கவும் அல்லது உள்ளிடவும்",\n      "alreadyExistIn": "ஏற்கனவே இதில் உள்ளது:",',
        '      "pleaseSelectEnterPlaylistName":\n          "பிளேலிஸ்ட் பெயரைத் தேர்ந்தெடுக்கவும் அல்லது உள்ளிடவும்",\n      "pleaseSelectOrCreate": "பிளேலிஸ்ட்டைத் தேர்ந்தெடுக்கவும் அல்லது புதியதை உருவாக்கவும்",\n      "playlistNameAlreadyExists": "இந்தப் பெயரில் பிளேலிஸ்ட் ஏற்கனவே உள்ளது",\n      "alreadyExistIn": "ஏற்கனவே இதில் உள்ளது:",',
    ),
    (
        '      "mediaFile": "ஊடகக் கோப்பு",\n      "addedToFavourite": "விருப்பமானவற்றில் சேர்க்கப்பட்டது",\n',
        '      "mediaFile": "ஊடகக் கோப்பு",\n      "mediaFile:": "ஊடகக் கோப்பு",\n      "addedToFavourite": "விருப்பமானவற்றில் சேர்க்கப்பட்டது",\n',
    ),
    (
        '      "hereIsMyFeedback:": "இதோ எனது கருத்து:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "இதோ எனது கருத்து:",\n      "hereIsMyFeedback:": "இதோ எனது கருத்து:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "A-B நீக்கப்பட்டது",\n      "videoSettings": "வீடியோ அமைப்புகள்",\n',
        '      "abCleared": "A-B நீக்கப்பட்டது",\n      "abSetPointA": "புள்ளி A அமைக்கவும்",\n      "abSetPointB": "புள்ளி B அமைக்கவும்",\n      "abClearRepeat": "A-B மீண்டும் இயக்கத்தை அழிக்கவும்",\n      "videoSettings": "வீடியோ அமைப்புகள்",\n',
    ),
    (
        '      "enterNewName": "புதிய பெயரை உள்ளிடவும்",\n      "videoRenamedSuccessfully": "வீடியோ பெயர் வெற்றிகரமாக மாற்றப்பட்டது!",\n',
        '      "enterNewName": "புதிய பெயரை உள்ளிடவும்",\n      "pleaseEnterValidUrl": "செல்லுபடியாகும் URL ஐ உள்ளிடவும்",\n      "videoRenamedSuccessfully": "வீடியோ பெயர் வெற்றிகரமாக மாற்றப்பட்டது!",\n',
    ),
    (
        '      "textScale": "உரை அளவு (%)",\n    },\n    \'ur\': {\n',
        '''      "textScale": "உரை அளவு (%)",
      "100": "100",
      "fileInformation": "கோப்பு தகவல்",
      "format": "வடிவம்",
      "created": "உருவாக்கப்பட்டது",
      "retry": "மீண்டும் முயற்சி",
      "albums": "ஆல்பங்கள்",
      "fileLocation": "கோப்பு இருப்பிடம்",
    },
    'ur': {
''',
    ),
    # ur
    (
        "      'privacyPolicy': 'پرائیویسی پالیسی',\n      \"playlist\": \"پلے لسٹ\",",
        "      'privacyPolicy': 'پرائیویسی پالیسی',\n      'otherSettings': 'دیگر ترتیبات',\n      \"playlist\": \"پلے لسٹ\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "براہ کرم پلے لسٹ کا نام منتخب کریں یا درج کریں",\n      "alreadyExistIn": "پہلے سے موجود ہے میں",',
        '      "pleaseSelectEnterPlaylistName":\n          "براہ کرم پلے لسٹ کا نام منتخب کریں یا درج کریں",\n      "pleaseSelectOrCreate": "پلے لسٹ منتخب کریں یا نئی بنائیں",\n      "playlistNameAlreadyExists": "اس نام کی پلے لسٹ پہلے سے موجود ہے",\n      "alreadyExistIn": "پہلے سے موجود ہے میں",',
    ),
    (
        '      "mediaFile": "میڈیا فائل",\n      "addedToFavourite": "پسندیدہ میں شامل کر دیا گیا",\n',
        '      "mediaFile": "میڈیا فائل",\n      "mediaFile:": "میڈیا فائل",\n      "addedToFavourite": "پسندیدہ میں شامل کر دیا گیا",\n',
    ),
    (
        '      "hereIsMyFeedback:": "یہ میرا فیڈ بیک ہے:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "یہ میرا فیڈ بیک ہے:",\n      "hereIsMyFeedback:": "یہ میرا فیڈ بیک ہے:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "A-B تکرار ختم کر دی گئی",\n      "videoSettings": "ویڈیو کی ترتیبات",\n',
        '      "abCleared": "A-B تکرار ختم کر دی گئی",\n      "abSetPointA": "پوائنٹ A سیٹ کریں",\n      "abSetPointB": "پوائنٹ B سیٹ کریں",\n      "abClearRepeat": "A-B تکرار صاف کریں",\n      "videoSettings": "ویڈیو کی ترتیبات",\n',
    ),
    (
        '      "enterNewName": "نیا نام درج کریں",\n      "videoRenamedSuccessfully": "ویڈیو کا نام کامیابی سے تبدیل ہو گیا!",\n',
        '      "enterNewName": "نیا نام درج کریں",\n      "pleaseEnterValidUrl": "براہ کرم درست URL درج کریں",\n      "videoRenamedSuccessfully": "ویڈیو کا نام کامیابی سے تبدیل ہو گیا!",\n',
    ),
    (
        '      "textScale": "تحریر کا پیمانہ (%)",\n    },\n  };\n',
        '''      "textScale": "تحریر کا پیمانہ (%)",
      "100": "100",
      "fileInformation": "فائل کی معلومات",
      "format": "فارمیٹ",
      "created": "بنایا گیا",
      "retry": "دوبارہ کوشش کریں",
      "albums": "البمز",
      "fileLocation": "فائل کا مقام",
    },
  };
''',
    ),
]


def main() -> None:
    s = P.read_text(encoding="utf-8")
    for i, (o, n) in enumerate(PATCHES):
        if o not in s:
            raise SystemExit(f"Patch {i} missing anchor:\n{o[:120]}...")
        s = s.replace(o, n, 1)
    P.write_text(s, encoding="utf-8")
    print("Applied", len(PATCHES), "patches OK")


if __name__ == "__main__":
    main()
