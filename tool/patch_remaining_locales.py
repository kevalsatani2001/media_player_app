# -*- coding: utf-8 -*-
"""Apply missing-key patches to fr, de, gu, hi, id, it, ja, ko, ms, mr, fa, pl, pt, es, sv, ta, ur."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PATH = ROOT / "lib/utils/app_string.dart"

# (old_snippet, new_snippet) — each old must be unique in file. Order matters.
PATCHES: list[tuple[str, str]] = [
    # --- French ---
    (
        "      'privacyPolicy': 'Politique de confidentialité',\n      \"playlist\": \"Liste de lecture\",",
        "      'privacyPolicy': 'Politique de confidentialité',\n      'otherSettings': 'Autres paramètres',\n      \"playlist\": \"Liste de lecture\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName": "Veuillez sélectionner ou saisir un nom",\n      "alreadyExistIn": "Existe déjà dans",',
        '      "pleaseSelectEnterPlaylistName": "Veuillez sélectionner ou saisir un nom",\n      "pleaseSelectOrCreate": "Veuillez sélectionner ou créer une liste de lecture",\n      "playlistNameAlreadyExists": "Une liste de lecture porte déjà ce nom",\n      "alreadyExistIn": "Existe déjà dans",',
    ),
    (
        '      "mediaFile": "Fichier multimédia",\n      "addedToFavourite": "Ajouté aux favoris",\n',
        '      "mediaFile": "Fichier multimédia",\n      "mediaFile:": "Fichier multimédia",\n      "addedToFavourite": "Ajouté aux favoris",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Voici mon avis :",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Voici mon avis :",\n      "hereIsMyFeedback:": "Voici mon avis :",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "Répétition A-B effacée",\n      "videoSettings": "Paramètres vidéo",\n',
        '      "abCleared": "Répétition A-B effacée",\n      "abSetPointA": "Définir le point A",\n      "abSetPointB": "Définir le point B",\n      "abClearRepeat": "Effacer la répétition A-B",\n      "videoSettings": "Paramètres vidéo",\n',
    ),
    (
        '      "enterNewName": "Entrez le nouveau nom",\n      "videoRenamedSuccessfully": "Vidéo renommée avec succès !",\n',
        '      "enterNewName": "Entrez le nouveau nom",\n      "pleaseEnterValidUrl": "Veuillez entrer une URL valide",\n      "videoRenamedSuccessfully": "Vidéo renommée avec succès !",\n',
    ),
    (
        '      "textScale": "Échelle du texte (%)",\n    },\n    \'de\': {\n',
        '''      "textScale": "Échelle du texte (%)",
      "100": "100",
      "fileInformation": "Informations sur le fichier",
      "format": "Format",
      "created": "Créé",
      "retry": "Réessayer",
      "albums": "Albums",
      "fileLocation": "Emplacement du fichier",
    },
    'de': {
''',
    ),
    # --- German ---
    (
        "      'privacyPolicy': 'Datenschutzerklärung',\n      \"playlist\": \"Playlist\",",
        "      'privacyPolicy': 'Datenschutzerklärung',\n      'otherSettings': 'Weitere Einstellungen',\n      \"playlist\": \"Playlist\",",
    ),
    (
        '      "pleaseSelectEnterPlaylistName":\n          "Bitte Playlist-Namen wählen oder eingeben",\n      "alreadyExistIn": "Bereits vorhanden in",',
        '      "pleaseSelectEnterPlaylistName":\n          "Bitte Playlist-Namen wählen oder eingeben",\n      "pleaseSelectOrCreate": "Bitte Playlist wählen oder neu erstellen",\n      "playlistNameAlreadyExists": "Eine Playlist mit diesem Namen existiert bereits",\n      "alreadyExistIn": "Bereits vorhanden in",',
    ),
    (
        '      "mediaFile": "Mediendatei",\n      "addedToFavourite": "Zu Favoriten hinzugefügt",\n',
        '      "mediaFile": "Mediendatei",\n      "mediaFile:": "Mediendatei",\n      "addedToFavourite": "Zu Favoriten hinzugefügt",\n',
    ),
    (
        '      "hereIsMyFeedback:": "Hier ist mein Feedback:",\n      "checkOutThisAmazing":\n',
        '      "hereIsMyFeedback": "Hier ist mein Feedback:",\n      "hereIsMyFeedback:": "Hier ist mein Feedback:",\n      "checkOutThisAmazing":\n',
    ),
    (
        '      "abCleared": "A-B Wiederholung gelöscht",\n      "videoSettings": "Video-Einstellungen",\n',
        '      "abCleared": "A-B Wiederholung gelöscht",\n      "abSetPointA": "Punkt A setzen",\n      "abSetPointB": "Punkt B setzen",\n      "abClearRepeat": "A-B Wiederholung löschen",\n      "videoSettings": "Video-Einstellungen",\n',
    ),
    (
        '      "enterNewName": "Neuen Namen eingeben",\n      "videoRenamedSuccessfully": "Video erfolgreich umbenannt!",\n',
        '      "enterNewName": "Neuen Namen eingeben",\n      "pleaseEnterValidUrl": "Bitte eine gültige URL eingeben",\n      "videoRenamedSuccessfully": "Video erfolgreich umbenannt!",\n',
    ),
    (
        '      "textScale": "Text-Skalierung (%)",\n    },\n    \'gu\': {\n',
        '''      "textScale": "Text-Skalierung (%)",
      "100": "100",
      "fileInformation": "Dateiinformationen",
      "format": "Format",
      "created": "Erstellt",
      "retry": "Erneut versuchen",
      "albums": "Alben",
      "fileLocation": "Dateispeicherort",
    },
    'gu': {
''',
    ),
]


def main() -> None:
    s = PATH.read_text(encoding="utf-8")
    for i, (old, new) in enumerate(PATCHES):
        if old not in s:
            raise SystemExit(f"Patch {i} anchor not found:\n---\n{old[:200]}\n---")
        s = s.replace(old, new, 1)
    PATH.write_text(s, encoding="utf-8")
    print(f"Applied {len(PATCHES)} replacements OK")


if __name__ == "__main__":
    main()
