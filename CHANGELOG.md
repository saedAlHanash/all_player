## 2.0.0
- Added a per-video metadata cache (`AllPlayerCache`) on top of m_cubit's `CachingService`:
  - stream/quality urls, cached until their signed url expires (YouTube `expire`, otherwise 30 min),
  - thumbnail url, shown behind the loader (YouTube is derived from the id, Vimeo/Dailymotion are cached),
  - resume position (`AllPlayerConfig.resumePlayback`),
  - remembered quality / speed / volume (`AllPlayerConfig.rememberPreferences`).
- Added optional video-bytes cache `AllPlayerVideoCache` (`video_partial_cache`): call
  `AllPlayerVideoCache.init()` once. Used for `network`, `networkQualityUrls`, `youtube`, `vimeo`
  and `dailymotion`, for progressive MP4 and for HLS (`.m3u8` playlists + segments, offline replay);
  skipped for DASH, asset/file, web, live streams and videos with `httpHeaders`.
- Vimeo: `progressive` MP4 files are used when available (real url per quality, byte-range cacheable);
  otherwise the HLS master playlist is exposed as a single entry (it was repeated for every quality before).
  Falls back to the direct url if the local proxy fails. Disable per video with `AllPlayerConfig.cacheVideo`.
- Cache manager UI: `AllPlayerCacheManagerPage.open(context)` (or embed `AllPlayerCacheManager`):
  used / free / limit, cache limit and eviction strategy (remembered across starts), clear all /
  clear old, and every cached video with thumbnail, title, size, cached % and a `CacheTimelineBar`
  showing where it is cached (per quality; exact for HLS). Pin or delete a video or one quality.
  Uses only the app's `Theme`; texts via `AllPlayerCacheLabels` (`.arabic()` included).
  `AllPlayerCacheCubit` drives it and can back a custom UI.
- `PlayVideoFrom.*` take `title` and `thumbnail` (shown in the cache manager and while loading).
- `httpHeaders` on youtube / vimeo / dailymotion are used for the platform API only: they no
  longer disable the video cache and are not sent to the stream CDN.
- Each quality is cached under its own id (`<cacheKey>@<quality>`), HLS variants included.
- Minimum Dart SDK is now 3.12.2 (required by `video_partial_cache`).
- New `AllPlayerConfig.cacheEnabled` and `cacheId` on `PlayVideoFrom.network` / `networkQualityUrls` / `auto`.
- `AllPlayerState.thumbnailUrl` added.
- Fixed: changing quality dropped `httpHeaders`, `formatHint` and captions.
- Breaking: removed `AllVideoPlayer`, `AllVideoState`, `AllVideoPlayerType` aliases,
  `AllPlayerState/AllPlayerController.videoState`, `AllPlayerConfig.forcedVideoFocus`
  and the unused `videoThumpBuketName`.

## 1.0.0
- Rebranded to `all_player`.
- Replaced GetX architecture with clean `Cubit` (`flutter_bloc`) state management.
- Divided YouTube playback into `PlayVideoFrom.youtubePlayer` (native `video_player` stream) and `PlayVideoFrom.youtubeIframe` (`youtube_player_flutter` WebView iframe).
- Added smart platform auto-detection via `PlayVideoFrom.auto(...)` with configurable `preferYoutubeMode`.
- Modernized all Flutter widgets, removed deprecated APIs (`PopScope`, `KeyboardListener`).
- Complete elimination of legacy player references.

## 0.2.2
- fixed broken vimeo api requests
- upgraded minimum sdk version from ">=2.17.0 <4.0.0" to ">=3.0.0 <4.0.0"
- upgraded all the dependencies to latest version
- fix typos in README.md

## 0.2.1
- upgraded all dependencies 
- upgraded `http` lib to `^1.1.0`
- fix fullscreen issue in IOS

## 0.2.0
  - upgraded dependencies 
  - migrate from `wakelock` to `wakelock_plus` PR [#129](https://github.com/newtaDev/all_player/pull/129)
  - fixed all lint rules
  - migrated `VideoPlayerController.network` to `VideoPlayerController.networkUrl`
  - Breaking:
    - In `PlayVideoFrom.file` [file] param datatype changed from [dynamic] to [File]
## 0.1.5
  - merged PR #103
    - support unlisted vimeo videos
  - upgraded dependencies 
  - Updated Readme file
## 0.1.4
  - added all player logo to pub.dev
## 0.1.3
  - fix: unable to find directory entry in pubspec.yaml #114
  - merged PR #109 
## 0.1.2
  - fixed #82
## 0.1.1
  - Feature
    - support vimeo private video [ref](https://github.com/newtaDev/all_player#how-to-play-video-from-vimeo-private-videos)
    - double tap ripple effect added
  - upgraded dependencies
  - merged PR #66 #77 #78
## 0.1.0

- Breaking change:

  - In `AllPlayerConfig` `initialVideoQuality` changed to `videoQualityPriority` to support priority of video qualities

  ```dart
  controller = AllPlayerController(
  allPlayerConfig: const AllPlayerConfig(
    videoQualityPriority: [1080, 720, 360],
  ),
  )..initialise()
  ```

- Features

  - Support for youtube live videos By [`(@vodino)`](https://github.com/vodino)
  - Added: `videoQualityPriority` to `AllPlayerConfig` By [`(@emersonsiega)`](https://github.com/emersonsiega)
  - Added: callback `onToggleFullScreen` when changes in fullscreen mode [#48](https://github.com/newtaDev/all_player/issues/48)
  - Added: `hideOverlay` and `showOverlay` functions to controller

- Bug Fixes
  - Merged PR #54 By [`(@emersonsiega)`](https://github.com/emersonsiega)
    - Fix unhandled exception on initialization [#49](https://github.com/newtaDev/all_player/issues/49)
    - Add video quality priority list
    - Changes in `onToggleFullScreen`

## 0.0.8

- Merged PR #37 & #38, By [`(@Jeferson505)`](https://github.com/Jeferson505)
  - Added `AllPlayerLabels` param to `AllVideoPlayer` widget
  - Added AllPlayerLabels usage example in `from_asset` file
  - Seted `normal` playback speed to `1x`
- bug fix and added example for playing videos in list

## 0.0.7

- dependencies upgraded
  - video_player: ^2.4.5
- code refactor

## 0.0.6

- Upgraded to Dart 2.17.0
- Bug fixes
- Added some examples

## 0.0.5

- Features
  - Added support for thumbnails
  - Added `isFullScreen` getter to controller
- Updated docs

## 0.0.4

- Features
  - support for RTL (by @karbalaidev)
  - initialVideoQuality added
- Bug fixes

## 0.0.3

- Bug fix #4

## 0.0.2

- Ignored .mp4 video file in pub

## 0.0.1

- Initial release
