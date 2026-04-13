# CatLock

[English](../README.md) | [中文](README_zh.md) | **Deutsch**

Eine leichtgewichtige macOS-Menüleisten-App, die Tastatur und Maus sperrt — weil Katzen eigene Vorstellungen von deiner Arbeit haben.

<p align="center">
  <img src="pics/main-interface.png" alt="CatLock Hauptfenster" width="280">
</p>

Drücke eine anpassbare Tastenkombination (Standard: `Cmd+Shift+L`) in jeder App, um sofort alle Eingaben zu sperren. Ein Vollbild-Overlay mit einer Entsperr-Schaltfläche wird angezeigt. Drücke die Tastenkombination erneut oder klicke auf die Schaltfläche zum Entsperren.

## Funktionen

- **Globale Tastenkombination** — Funktioniert in jeder App, auch wenn CatLock im Hintergrund läuft
- **Anpassbare Tastenkombination** — Beliebige Tastenkombination in den Einstellungen aufnehmen
- **Datenschutzmodus** — Bildschirm wird im gesperrten Zustand komplett schwarz
- **Menüleisten-App** — Lebt in der Menüleiste, stört nicht
- **25 Sprachen** — Erkennt automatisch die Systemsprache
- **Ruhezustand-Verhinderung** — Hält den Mac wach, damit lang laufende Aufgaben nicht unterbrochen werden

## Sperrmodus

Im gesperrten Zustand bedeckt ein halbtransparentes Overlay den Bildschirm. Der Desktop bleibt sichtbar, aber alle Tastatur- und Mauseingaben werden blockiert.

<p align="center">
  <img src="pics/normal-lock-mode.png" alt="Normaler Sperrmodus" width="600">
</p>

## Datenschutzmodus

Musst du kurz weg? Aktiviere den Datenschutzmodus in den Einstellungen — das Overlay wird vollständig schwarz und verbirgt alles auf dem Bildschirm.

<p align="center">
  <img src="pics/privacy-mode.png" alt="Datenschutzmodus" width="600">
</p>

## Einstellungen

Passe deine Tastenkombination an und schalte den Datenschutzmodus um.

<p align="center">
  <img src="pics/settings.png" alt="Einstellungen" width="320">
</p>

## Warum CatLock?

Die Katze läuft über die Tastatur. Das Kleinkind entdeckt die Entf-Taste. Du wischt die Tastatur ab und löst versehentlich einen Shortcut aus, der den Desktop umstellt. CatLock fängt alle Eingaben auf Systemebene ab — im gesperrten Zustand erreichen keine Ereignisse irgendeine Anwendung.

## So funktioniert es

CatLock verwendet macOS CGEvent Taps, um Tastatur- und Mausereignisse abzufangen, bevor sie eine Anwendung erreichen. Ein leichtgewichtiger Listen-Only-Tap läuft ständig, um die Tastenkombination zu erkennen. Im gesperrten Zustand blockiert ein zweiter Tap alle Eingaben außer der Entsperr-Tastenkombination. Dies erfordert die Bedienungshilfen-Berechtigung, die CatLock bei der ersten Verwendung anfordert.

## Installation

1. Lade die neueste `.dmg`-Datei von [Releases](https://github.com/hou-physics/CatLock/releases) herunter
2. Öffne die `.dmg` und ziehe CatLock in den Programme-Ordner
3. Öffne CatLock. macOS zeigt eine Warnung — klicke auf **Fertig** (nicht auf „In den Papierkorb legen")
4. Gehe zu **Systemeinstellungen → Datenschutz & Sicherheit**, scrolle nach unten und klicke auf **Trotzdem öffnen**
5. CatLock fragt nach der Bedienungshilfen-Berechtigung — klicke auf die Schaltfläche, um sie in den Systemeinstellungen zu erteilen

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

GPL-3.0
