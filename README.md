# MacTweaks

Fünf kleine, kostenlose Apps, die deinen Mac angenehmer machen: bessere Tastenkürzel, ein aufgeräumter Home-Ordner, ein KI-Assistent, eine Dynamic Island für die Notch und eine aufgeräumte Menüleiste samt Dock. Alle sind auf Deutsch, laufen still in der Menüleiste und sind Open Source (MIT).

| App | Wofür | macOS | Mac | Claude-Abo |
|---|---|---|---|---|
| [**KeyFlow**](#keyflow) | Tastenkürzel und Fenster | 14 oder neuer | Apple Silicon | nicht nötig |
| [**TidyMac**](#tidymac) | Dateien aufräumen | 15 oder neuer | Apple Silicon | optional |
| [**MacBuddy**](#macbuddy) | KI-Assistent | 26 oder neuer | Apple Silicon | nötig |
| [**NotchIsland**](#notchisland) | Notch als Dynamic Island | 14 oder neuer | Apple Silicon und Intel | nicht nötig |
| [**MenuTidy**](#menutidy) | Menüleiste und Dock aufräumen | 27 oder neuer | Apple Silicon | nicht nötig |

## Alle auf einmal installieren

Öffne das **Terminal** (Programme › Dienstprogramme › Terminal), füge diese Zeile ein und drücke Return:

```bash
curl -fsSL https://raw.githubusercontent.com/Vyp3er/MacTweaks/main/install.sh | bash
```

Das [Installationsskript](install.sh)

- holt von GitHub die neueste Version jeder App,
- prüft jede Datei gegen die SHA-256-Prüfsumme von GitHub und kontrolliert die Signatur der App,
- überspringt Apps, die auf deinem Mac nicht laufen (zu altes macOS, Intel statt Apple Silicon),
- legt die Apps in den Ordner „Programme“ (ohne Schreibrechte dort nach `~/Applications`) und braucht kein Administrator-Passwort,
- lässt aktuelle Apps in Ruhe. Bei einem Update beendet es die alte Version, legt sie in den Papierkorb und startet die neue. Gelöscht wird nichts.

**Nur bestimmte Apps:** Namen anhängen, zum Beispiel

```bash
curl -fsSL https://raw.githubusercontent.com/Vyp3er/MacTweaks/main/install.sh | bash -s -- TidyMac NotchIsland
```

**Updates:** Dieselbe Zeile später einfach noch einmal ausführen. Mit `bash -s -- --list` statt `bash` siehst du nur, welche Versionen verfügbar und installiert sind, ohne etwas zu ändern.

> **Gut zu wissen:** Die Apps sind nicht bei Apple notarisiert. Lädst du sie im Browser herunter, blockiert macOS den ersten Start einmal, bis du ihn unter Systemeinstellungen › Datenschutz & Sicherheit mit „Dennoch öffnen“ erlaubst. Lädt das Skript sie, setzt macOS keine Download-Markierung, und dieser Schritt entfällt. Führe es deshalb nur aus, wenn du dieser Quelle vertraust. Ansehen kannst du es vorher so:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/Vyp3er/MacTweaks/main/install.sh -o mactweaks-install.sh
> ```
>
> Danach `open -e mactweaks-install.sh` zum Lesen und `bash mactweaks-install.sh` zum Ausführen.

Nach der Installation richtest du jede App beim ersten Start kurz ein (Berechtigungen, bei MacBuddy und TidyMac eventuell Claude). Die Begrüßungsfenster der Apps führen dich durch; die Details stehen in den Anleitungen unten.

---

## KeyFlow

**Tastenkürzel auf dem Mac, einfacher.** Fenster per Kürzel oder Ziehen anordnen, Layouts für mehrere Monitore, Caps Lock als Hyper-Taste, App-Kürzel und Text-Bausteine. ⌘ gedrückt halten zeigt alle Kürzel der aktiven App als durchsuchbaren Spickzettel.

- **Fenster-Manager:** Hälften, Viertel, Drittel, Maximieren, Zentrieren, Snap-Zonen beim Ziehen
- **Layouts:** Fensteranordnungen speichern und wiederherstellen, passend zum Monitor-Setup
- **Hyper-Taste:** Caps Lock wird zu ⌃⌥⇧⌘, kurz angetippt zu Esc. Hyper + Buchstabe öffnet eine App oder wechselt zu ihr
- **Text-Expander:** `;mail` wird zu deinem Textbaustein, mit Datum, Zwischenablage und Cursor-Platzhalter

Braucht die Berechtigungen Bedienungshilfen und Eingabeüberwachung.

[Download](https://github.com/Vyp3er/KeyFlow/releases/latest) · [Installationsanleitung](https://github.com/Vyp3er/KeyFlow/blob/main/INSTALL.md) · [Quellcode](https://github.com/Vyp3er/KeyFlow)

## TidyMac

**Räumt deinen Mac auf, ohne etwas kaputt zu machen.** Auf Knopfdruck sortiert TidyMac deinen Home-Ordner oder ausgewählte Ordner wie Downloads und Schreibtisch: Es legt sinnvolle Ordner an, verschiebt Dateien und gibt nichtssagenden Namen wie `IMG_4711.jpg` einen lesbaren Namen.

- **Erst Vorschau, dann ausführen:** Jede geplante Aktion mit Begründung und Sicherheit, einzeln abwählbar
- **Schutz:** Projektordner (Git, Xcode, Node, Python, LaTeX …), Library, Apps, Cloud-Ordner und geöffnete Dateien bleiben unangetastet. Nichts wird überschrieben, Löschen heißt immer Papierkorb
- **Rückgängig:** Jeder Lauf und jede einzelne Aktion lässt sich zurücknehmen
- **Extras:** Duplikate finden, Aufräum-Vorschläge (große, alte, ungenutzte Dateien), Hintergrund-Modus für Downloads

Eindeutige Fälle erledigen Regeln. Für unklare Dateien kann TidyMac Claude fragen, über dein eigenes Abo oder einen API-Key, oder ganz ohne KI arbeiten. An Claude gehen nur Dateinamen, Metadaten und kurze Textauszüge, nie ganze Dateien. Braucht den Festplattenvollzugriff.

[Download](https://github.com/Vyp3er/TidyMac/releases/latest) · [Installationsanleitung](https://github.com/Vyp3er/TidyMac/blob/main/INSTALL.md) · [Quellcode](https://github.com/Vyp3er/TidyMac)

## MacBuddy

**Ein KI-Assistent, der deinen Mac bedienen kann.** Drück ⌃⌘B, und neben deinem Mauszeiger erscheint ein zweiter Cursor. Sag oder schreib ihm, was er tun soll; er klickt und tippt sichtbar für dich, wie ein Mensch am Mac. Ein Ersatz für die KI-Funktionen von Siri, die in Europa fehlen.

- **T** Text, **V** Sprache (lokal erkannt), **S** Screenshot, **E** Bildschirm erklären, **R** markierten Text umschreiben oder übersetzen, **F** Dateien in natürlicher Sprache finden
- Riskante Aktionen nur nach Bestätigung, **Esc** stoppt sofort alles, Aktionsprotokoll in der Menüleiste
- Routinen und Gedächtnis

Nutzt Claude über dein eigenes Claude-Abo (Pro oder Max) und das offizielle Programm Claude Code. Braucht Bedienungshilfen und Bildschirmaufnahme.

[Download](https://github.com/Vyp3er/MacBuddy/releases/latest) · [Installationsanleitung](https://github.com/Vyp3er/MacBuddy/blob/main/INSTALL.md) · [Quellcode](https://github.com/Vyp3er/MacBuddy)

## NotchIsland

**Die Notch deines MacBooks wird zur Dynamic Island.** Fährst du mit der Maus auf die Notch oder ziehst eine Datei darüber, klappt sie mit einer Animation auf.

- **Ablage:** Dateien per Drag & Drop parken und wieder herausziehen
- **Musik:** Cover, Fortschritt und Steuerung für Musik, Spotify und Browser
- **Kamera:** Spiegel vor Videocalls
- **Kalender:** Termine mit „Beitreten“-Knopf für Zoom, Teams, Meet und Webex
- **Zwischenablage:** Verlauf, Passwörter werden ignoriert
- **Timer:** „5min“, „Pizza 12 min“ oder „@17:30“ eintippen

Am schönsten auf einem MacBook mit Notch. Ohne Notch erscheint die Island oben mittig.

[Download](https://github.com/Vyp3er/NotchIsland/releases/latest) · [Installationsanleitung](https://github.com/Vyp3er/NotchIsland/blob/main/INSTALLATION.md) · [Quellcode](https://github.com/Vyp3er/NotchIsland)

## MenuTidy

**Nichts verschwindet mehr hinter der Notch.** MenuTidy sortiert die Icons deiner Menüleiste in drei Bereiche: *Sichtbar*, *Versteckt* (ein Klick auf ‹ klappt sie aus) und *Immer versteckt* (⌥-Klick, eigene Leiste unter der Menüleiste). Dazu räumt es das Dock auf.

- **Notch-Warnung:** zeigt, welche Icons hinter der Notch landen, und versteckt auf Wunsch die unwichtigsten automatisch
- **Layout-Editor:** Apps per Drag & Drop zwischen die Bereiche ziehen; Profile wechseln je nach Monitor, App oder Akku, auch per Kurzbefehl für Fokus-Modi
- **Vorschläge:** zählt lokal, welche Icons du anklickst, und schlägt vor, was weg kann
- **Dock-Aufräumer:** Apps, die du lange nicht geöffnet hast, wandern ins Dock-Archiv und kommen mit einem Klick zurück, mit Backup und „Rückgängig“

Braucht macOS 27 und die Berechtigung Bedienungshilfen. Noch nicht im Installationsskript: MenuTidy baust du mit Xcode 27 selbst, die Anleitung erklärt die zwei Befehle.

[Installationsanleitung](https://github.com/Vyp3er/MenuTidy/blob/main/INSTALLATION.md) · [Quellcode](https://github.com/Vyp3er/MenuTidy)

---

## Zusammen noch besser

- **MacBuddy + NotchIsland:** NotchIsland zeigt Status, Ergebnisse und Bestätigungen von MacBuddy direkt an der Notch, mit Not-Aus daneben.
- **MacBuddy + TidyMac:** Beide nutzen dieselbe Claude-Code-Anmeldung. Einmal einrichten reicht:
  ```bash
  curl -fsSL https://claude.ai/install.sh | bash
  ```
  ```bash
  ~/.local/bin/claude auth login
  ```
  Die Anfragen beider Apps zählen gegen das Nutzungslimit deines Abos (geteilt mit claude.ai). Die Apps sehen deine Zugangsdaten nie.

## Fragen

**Kostet das etwas?** Die Apps sind kostenlos. Für MacBuddy brauchst du ein Claude-Abo (Pro oder Max), für TidyMac ist es optional.

**Nach einem Update funktioniert eine App nicht mehr richtig.** Die Apps sind ohne Apple-Entwicklerzertifikat signiert. macOS vergisst deshalb nach jedem Update Berechtigungen wie Bedienungshilfen oder Festplattenvollzugriff. Schalte sie unter Systemeinstellungen › Datenschutz & Sicherheit einmal aus und wieder ein.

**Wie werde ich eine App wieder los?** Das steht jeweils am Ende der Installationsanleitung der App.

**Fehler gefunden oder eine Idee?** Schreib ein Issue im Repo der jeweiligen App.

Die Apps und das Installationsskript stehen unter der MIT-Lizenz.
