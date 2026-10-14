<h1 align="center">
  <br>
  <a href="https://getmythic.app">
    <img src="https://github.com/user-attachments/assets/dd702812-0d06-47a5-bd25-3f2dcf40aeee" 
      style="width: 20%; height: 20%;">
  </a>

  Mythic

  [![Discord](https://img.shields.io/discord/1154998702650425397?color=5865F2)](https://discord.com/invite/58NZ7fFqPy)
  [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
  [![Crowdin](https://badges.crowdin.net/mythicapp/localized.svg)](https://crowdin.com/project/mythicapp)
</h1>

<div align="center">
  <h3>A unique open-source game launcher for macOS with the ability to run Windows games, and integrate with other game sources.</h3>
  <!-- <em>All rights reserved.</em> -->
</div>

<br>

## Features
- [x] [Windows Game Support](https://github.com/MythicApp/Engine) (DX9-12) (64-bit)
- [ ] Steam Support (Windows version of Steam can still be manually downloaded) [!!view steam development roadmap here](https://github.com/orgs/MythicApp/projects/4)
- [x] Epic Games Support
- [x] Manual Game Imports
- [x] Game management
- [x] Discord Integration


There are more big things coming your way for Mythic, see the [roadmap](https://github.com/orgs/MythicApp/projects/2/views/2).
If you believe something's missing from the roadmap that we should add to the app, join our [Discord](https://discord.com/invite/58NZ7fFqPy), [open an issue](https://github.com/MythicApp/Mythic/issues/new/choose), or open a [pull request](https://github.com/MythicApp/Mythic/pulls).

## Download
[Download it now!](https://github.com/MythicApp/Mythic/releases)

* Please note Mythic is only available for macOS 14 (Sonoma) and above.
  To verify your Mac's compatibility with Sonoma, visit https://support.apple.com/en-us/105113

## Dependencies

### Wine for this fork

Windows apps use the installed Wine Staging at `/Applications/Wine Staging.app`, so upgrades from the tap do not require changing Mythic's version settings.
Install it with `brew install --cask adamekka/tap/wine@staging`; the tap also installs the GStreamer runtime for Windows video playback.
Mythic Engine still supplies Winetricks and DXVK, and its existing update workflow remains available.
The standard Wine runtime does not include Mythic Engine's MSync or D3DMetal optimizations.

### Windows Steam

Import Windows `steam.exe` as a local game. Mythic installs a browser-helper wrapper at launch that passes `--disable-gpu --single-process` directly to CEF to fix its black login window under Wine.
The original is saved beside it as `steamwebhelper.mythic-original.exe` and refreshed when a Steam update replaces the helper.
Steam launches with `-noverifyfiles` because its startup file check would undo the wrapper. Client updates stay enabled; if an update leaves the window black, close Steam and launch it again through Mythic.

Building this fork requires `brew install mingw-w64`. Xcode compiles the Windows helper from `Support/SteamWebHelper/steamwebhelper.c` with Clang and bundles it automatically. The wrapper is adapted from [notpop's MIT-licensed Steam workaround](https://github.com/notpop/steam-on-m1-wine/tree/main/wrapper).

Mythic uses the following Swift dependencies:

- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) — The better way to deal with JSON data in Swift. 
- [SemanticVersion](https://github.com/SwiftPackageIndex/SemanticVersion) — Semantic version structuring & parsing
- [ColorfulX](https://github.com/Lakr233/ColorfulX) — An implementation using Metal for crafting multi-colored gradients.
- [Glur](https://github.com/joogps/Glur) — A SwiftUI library that uses Metal to display efficient progressive blurs
- [WhatsNewKit](https://github.com/SvenTiigi/WhatsNewKit) — A Swift Package to easily showcase your new app features.
- [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) — Firebase SDK for Apple App Development
- [SwiftUI-Shimmer](https://github.com/markiv/SwiftUI-Shimmer) — A super-light modifier that adds a shimmering effect to any SwiftUI View.
- [DockProgress](https://github.com/sindresorhus/DockProgress) — Show progress in your app's Dock icon

<sub>Copyright © 2023-2025 vapidinfinity. All rights reserved.</sub>
