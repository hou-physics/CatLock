# CatLock

[English](../README.md) | [中文](README_zh.md) | **Deutsch**

Eine leichtgewichtige macOS-Menüleisten-App, die Tastatur und Maus sperrt, um versehentliche Eingaben durch Katzen, Kinder oder beim Reinigen zu verhindern.

Drücken Sie eine anpassbare Tastenkombination (Standard: `Cmd+Shift+L`) in jeder App, um sofort alle Tastatur- und Mauseingaben zu sperren. Ein Vollbild-Overlay mit einer Entsperr-Schaltfläche wird angezeigt. Drücken Sie die Tastenkombination erneut oder klicken Sie auf die Schaltfläche zum Entsperren. So einfach ist das.

## Funktionen

- **Globale Tastenkombination** — Funktioniert in jeder App, auch wenn CatLock im Hintergrund läuft
- **Anpassbare Tastenkombination** — Beliebige Tastenkombination in den Einstellungen aufnehmen
- **Datenschutzmodus** — Optionales vollständig schwarzes Overlay, das den Bildschirminhalt verbirgt
- **Menüleisten-App** — Lebt in der Menüleiste, stört nicht
- **25 Sprachen** — Erkennt automatisch die Systemsprache
- **Ruhezustand-Verhinderung** — Hält den Mac während der Sperrung wach, damit lang laufende Aufgaben nicht unterbrochen werden

## Warum CatLock?

Die Katze läuft über die Tastatur. Das Kleinkind hämmert auf die Tasten. Sie reinigen die Tastatur und lösen versehentlich Shortcuts aus. CatLock löst all diese Probleme, indem es Eingaben auf Systemebene abfängt — im gesperrten Zustand erreichen keine Ereignisse irgendeine Anwendung.

## So funktioniert es

CatLock verwendet macOS CGEvent Taps, um Tastatur- und Mausereignisse abzufangen, bevor sie eine Anwendung erreichen. Ein leichtgewichtiger Listen-Only-Tap läuft ständig, um die Tastenkombination zu erkennen. Im gesperrten Zustand schluckt ein zweiter Tap alle Eingaben außer der Entsperr-Tastenkombination. Dies erfordert die Bedienungshilfen-Berechtigung, die CatLock bei der ersten Verwendung anfordert.

## Installation

1. Laden Sie die neueste `.dmg`-Datei von [Releases](../../releases) herunter
2. Öffnen Sie die `.dmg` und ziehen Sie CatLock in den Programme-Ordner
3. Öffnen Sie CatLock. macOS zeigt eine Warnung — klicken Sie auf **Fertig** (nicht auf „In den Papierkorb legen")
4. Gehen Sie zu **Systemeinstellungen → Datenschutz & Sicherheit**, scrollen Sie nach unten und klicken Sie auf **Trotzdem öffnen**
5. CatLock fragt nach der Bedienungshilfen-Berechtigung — klicken Sie auf die Schaltfläche, um sie in den Systemeinstellungen zu erteilen

> **Warum die Warnung?** CatLock ist Open-Source und kostenlos. Die Warnung erscheint, weil die App nicht mit einem kostenpflichtigen Apple-Entwicklerzertifikat (99 $/Jahr) signiert ist. Der Quellcode ist vollständig einsehbar in diesem Repository.

## Aus dem Quellcode bauen

```
git clone https://github.com/hou-physics/CatLock.git
cd CatLock
xcodebuild -scheme CatLock -configuration Release build
```

Die erstellte App befindet sich in `~/Library/Developer/Xcode/DerivedData/CatLock-*/Build/Products/Release/CatLock.app`.

## Voraussetzungen

- macOS 14.0 oder neuer
- Bedienungshilfen-Berechtigung (wird bei der ersten Verwendung angefordert)

## Lizenz

MIT
