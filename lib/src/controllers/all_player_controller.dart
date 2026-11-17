import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_html/html.dart' as uni_html;
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../all_player.dart';
import '../cache/all_player_cache.dart';
import '../cache/all_player_video_cache.dart';
import '../models/all_player_config.dart';
import '../models/all_player_labels.dart';
import '../models/all_progress_bar_config.dart';
import '../models/overlay_options.dart';
import '../models/play_video_from.dart';
import '../models/vimeo_models.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';
import '../utils/video_apis.dart';
import 'all_player_state.dart';

class AllPlayerController extends Cubit<AllPlayerState> {
  PlayVideoFrom playVideoFrom;
  AllPlayerConfig playerConfig;

  VideoPlayerController? videoCtr;
  YoutubePlayerController? youtubeIframeController;

  Timer? _overlayTimer;
  Timer? _leftDoubleTapTimer;
  Timer? _rightDoubleTapTimer;
  Timer? _hoverOverlayTimer;

  AllPlayerPrefs _prefs = const AllPlayerPrefs();
  DateTime _lastPositionSave = DateTime.fromMillisecondsSinceEpoch(0);
  static const _positionSaveInterval = Duration(seconds: 5);

  int doubleTapForwardSeconds = 10;
  VoidCallback? onVideoQualityChanged;
  Future<void> Function(bool isFullScreen)? onToggleFullScreen;
  WidgetBuilder? onLoading;
  Widget Function(OverLayOptions options)? overlayBuilder;
  Widget? videoTitle;
  DecorationImage? videoThumbnail;
  AllProgressBarConfig progressBarConfig = const AllProgressBarConfig();
  AllPlayerLabels playerLabels = const AllPlayerLabels();
  bool alwaysShowProgressBar = true;

  static const List<String> videoPlaybackSpeeds = [
    '0.25x',
    '0.5x',
    '0.75x',
    '1x',
    '1.25x',
    '1.5x',
    '1.75x',
    '2x',
  ];

  AllPlayerController({
    required this.playVideoFrom,
    this.playerConfig = const AllPlayerConfig(),
  }) : super(const AllPlayerState());

  bool get isIframe => playVideoFrom.playerType == AllPlayerType.youtubeIframe;

  String? get videoUrl => state.playingVideoUrl ?? playVideoFrom.dataSource;

  bool get isInitialised =>
      isIframe ? (youtubeIframeController != null) : (videoCtr?.value.isInitialized ?? false);

  bool get isVideoPlaying =>
      isIframe ? (state.playerStatus == AllPlayerStatus.playing) : (videoCtr?.value.isPlaying ?? false);

  bool get isVideoBuffering => isIframe ? false : (videoCtr?.value.isBuffering ?? false);

  bool get isVideoLooping => state.isLooping;

  bool get isFullScreen => state.isFullScreen;

  bool get isMute => state.isMute;

  AllPlayerStatus get playerStatus => state.playerStatus;

  VideoPlayerValue? get videoPlayerValue => videoCtr?.value;

  AllPlayerType get videoPlayerType => playVideoFrom.playerType;

  /// Cache key of the current video, or `null` when caching is off / unsupported.
  String? get _cacheKey => playerConfig.cacheEnabled ? playVideoFrom.cacheKey : null;

  Duration get totalVideoLength => state.videoDuration;

  Duration get currentVideoPosition => state.videoPosition;

  String get currentPlaybackSpeed => state.playbackSpeed;

  Future<void> initialise() async {
    emit(state.copyWith(playerStatus: AllPlayerStatus.loading));
    await _loadCachedExtras();
    if (isIframe) {
      await _initYoutubeIframe();
    } else {
      await _initVideoPlayer();
    }
  }

  /// Loads what is cached for this video so the UI can react immediately:
  /// the thumbnail (shown while loading) and the user's preferences.
  Future<void> _loadCachedExtras() async {
    final key = _cacheKey;
    if (key == null) return;

    if (playerConfig.rememberPreferences) {
      _prefs = await AllPlayerCache.prefs();
    }

    // Given by the app: remembered for the cache manager screen.
    unawaited(AllPlayerCache.saveTitle(key, playVideoFrom.title));
    final given = playVideoFrom.thumbnail ?? _youtubeThumbnail;
    if (given != null) unawaited(AllPlayerCache.saveThumbnail(key, given));

    final thumbnail = given ?? await AllPlayerCache.thumbnail(key);
    if (thumbnail != null && !isClosed) {
      emit(state.copyWith(thumbnailUrl: thumbnail));
    }
  }

  /// YouTube thumbnails are deterministic, no request or cache needed.
  String? get _youtubeThumbnail {
    final type = playVideoFrom.playerType;
    if (type != AllPlayerType.youtube && type != AllPlayerType.youtubeIframe) return null;
    final id = playVideoFrom.dataSource;
    return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  void _onThumbnail(String url) {
    final key = _cacheKey;
    if (key != null) unawaited(AllPlayerCache.saveThumbnail(key, url));
    if (!isClosed) emit(state.copyWith(thumbnailUrl: url));
  }

  Future<void> _initYoutubeIframe() async {
    try {
      final rawSource = playVideoFrom.dataSource ?? '';
      final videoId = rawSource.youtubeVideoId ?? rawSource;
      youtubeIframeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: playerConfig.autoPlay,
        params: playVideoFrom.youtubeParams ??
            const YoutubePlayerParams(
              mute: false,
              enableCaption: false,
              strictRelatedVideos: false,
              showControls: true,
              showFullscreenButton: true,
            ),
      );
      if (playerConfig.wakelockEnabled) {
        unawaited(WakelockPlus.enable().catchError((_) {}));
      }
      emit(state.copyWith(
        playerStatus: AllPlayerStatus.playing,
        playingVideoUrl: rawSource,
      ));
      allPlayerLog('YouTube IFrame player initialized');
    } catch (e) {
      emit(state.copyWith(
        playerStatus: AllPlayerStatus.error,
        errorMessage: e.toString(),
      ));
      allPlayerLog('YouTube IFrame init error: $e');
    }
  }

  Future<void> _initVideoPlayer() async {
    _proxied = false;
    try {
      final url = await _resolveVideoUrl();
      switch (playVideoFrom.playerType) {
        case AllPlayerType.network:
        case AllPlayerType.networkQualityUrls:
        case AllPlayerType.youtube:
        case AllPlayerType.vimeo:
        case AllPlayerType.vimeoPrivateVideos:
        case AllPlayerType.dailymotion:
          videoCtr = _createNetworkController(url, quality: state.currentQuality);
        case AllPlayerType.asset:
          videoCtr = VideoPlayerController.asset(
            playVideoFrom.dataSource!,
            closedCaptionFile: playVideoFrom.closedCaptionFile,
            package: playVideoFrom.package,
            videoPlayerOptions: playVideoFrom.videoPlayerOptions,
          );
        case AllPlayerType.file:
          if (kIsWeb) throw Exception('File does not support web');
          videoCtr = VideoPlayerController.file(
            playVideoFrom.file!,
            closedCaptionFile: playVideoFrom.closedCaptionFile,
            videoPlayerOptions: playVideoFrom.videoPlayerOptions,
          );
        case AllPlayerType.youtubeIframe:
          return;
      }

      await _initializeWithFallback(url, quality: state.currentQuality);
      videoCtr!.addListener(_videoListener);

      if (playerConfig.isLooping) {
        await videoCtr!.setLooping(true);
      }

      await _restoreFromCache();

      if (playerConfig.autoPlay) {
        await play();
      } else {
        emit(state.copyWith(
          playerStatus: AllPlayerStatus.paused,
          videoDuration: videoCtr!.value.duration,
          playingVideoUrl: url,
        ));
      }
      allPlayerLog('AllPlayer native controller initialized: $url');
    } catch (e) {
      emit(state.copyWith(
        playerStatus: AllPlayerStatus.error,
        errorMessage: e.toString(),
      ));
      allPlayerLog('AllPlayer native init error: $e');
    }
  }

  /// True while the current controller plays through the local byte cache.
  bool _proxied = false;

  /// Whether the bytes of this source may go through [AllPlayerVideoCache].
  bool get _canCacheBytes {
    if (!playerConfig.cacheVideo || !AllPlayerVideoCache.isEnabled) return false;
    // Per-video headers cannot be forwarded to the origin through the proxy.
    if (_streamHeaders.isNotEmpty) return false;
    switch (playVideoFrom.playerType) {
      case AllPlayerType.network:
      case AllPlayerType.networkQualityUrls:
      case AllPlayerType.youtube:
      case AllPlayerType.vimeo:
      case AllPlayerType.dailymotion:
        return true;
      default:
        return false;
    }
  }

  /// Headers sent to the stream itself. For youtube / vimeo / dailymotion the
  /// `httpHeaders` are meant for the platform API (e.g. a Vimeo token), the CDN
  /// stream does not need them, so they must not disable the byte cache.
  Map<String, String> get _streamHeaders {
    switch (playVideoFrom.playerType) {
      case AllPlayerType.youtube:
      case AllPlayerType.vimeo:
      case AllPlayerType.dailymotion:
        return const {};
      default:
        return playVideoFrom.httpHeaders;
    }
  }

  /// Every quality is a different file / media playlist, so it needs its own
  /// cache id (HLS variants would otherwise overwrite each other's segments).
  String? _videoCacheId(String url, int? quality) {
    // A network url without cacheId: the cache derives an id from the url.
    if (playVideoFrom.playerType == AllPlayerType.network && playVideoFrom.cacheId == null) {
      return null;
    }
    final key = playVideoFrom.cacheKey;
    if (key == null) return null;
    return quality == null ? key : '$key@$quality';
  }

  VideoPlayerController _createNetworkController(
    String url, {
    int? quality,
    bool useCache = true,
  }) {
    var playUrl = url;
    _proxied = false;
    if (useCache && _canCacheBytes) {
      final proxied = AllPlayerVideoCache.playableUrl(
        url,
        videoId: _videoCacheId(url, quality),
        title: playVideoFrom.title,
      );
      if (proxied != null) {
        playUrl = proxied;
        _proxied = true;
      }
    }

    return VideoPlayerController.networkUrl(
      Uri.parse(playUrl),
      closedCaptionFile: playVideoFrom.closedCaptionFile,
      formatHint: playVideoFrom.formatHint,
      videoPlayerOptions: playVideoFrom.videoPlayerOptions,
      httpHeaders: _streamHeaders,
    );
  }

  /// Initialises [videoCtr]; if it plays through the local cache proxy and that
  /// fails (e.g. cleartext to localhost blocked), retries with the direct url.
  Future<void> _initializeWithFallback(String url, {int? quality}) async {
    try {
      await videoCtr!.initialize();
    } catch (e) {
      if (!_proxied) rethrow;
      allPlayerLog('video cache proxy failed, using the direct url: $e');
      await videoCtr?.dispose();
      videoCtr = _createNetworkController(url, quality: quality, useCache: false);
      await videoCtr!.initialize();
    }
  }

  /// Applies the saved speed / volume and (optionally) resumes the video.
  Future<void> _restoreFromCache() async {
    final key = _cacheKey;
    if (key == null) return;

    if (playerConfig.rememberPreferences) {
      final speed = _prefs.speed;
      if (speed != null) setVideoPlayback(speed, persist: false);
      final volume = _prefs.volume;
      if (volume != null) await videoCtr?.setVolume(volume);
    }

    if (playerConfig.resumePlayback) {
      final saved = await AllPlayerCache.position(key);
      final duration = videoCtr?.value.duration ?? Duration.zero;
      if (saved != null && saved < duration) {
        await videoCtr?.seekTo(saved);
      }
    }
  }

  /// Returns cached stream urls when they are still valid, otherwise calls
  /// [fetch] and caches the result.
  Future<List<VideoQalityUrls>> _cachedStreams(
    Future<List<VideoQalityUrls>?> Function() fetch,
  ) async {
    final key = _cacheKey;
    if (key != null) {
      final cached = await AllPlayerCache.streams(key);
      if (cached != null) {
        allPlayerLog('stream urls loaded from cache: $key');
        return cached;
      }
    }

    final urls = await fetch() ?? [];
    if (key != null) unawaited(AllPlayerCache.saveStreams(key, urls));
    return urls;
  }

  Future<String> _resolveVideoUrl() async {
    switch (playVideoFrom.playerType) {
      case AllPlayerType.network:
        emit(state.copyWith(playingVideoUrl: playVideoFrom.dataSource));
        return playVideoFrom.dataSource!;
      case AllPlayerType.networkQualityUrls:
        return _pickQualityUrl(playVideoFrom.videoQualityUrls ?? []);
      case AllPlayerType.youtube:
        final videoId = playVideoFrom.dataSource?.youtubeVideoId ?? playVideoFrom.dataSource!;
        final urls = await _cachedStreams(
          () => VideoApis.getYoutubeVideoQualityUrls(videoId, playVideoFrom.live),
        );
        return _pickQualityUrl(urls);
      case AllPlayerType.vimeo:
        final videoId = playVideoFrom.dataSource?.vimeoVideoId ?? playVideoFrom.dataSource!;
        final hash = playVideoFrom.hash ?? playVideoFrom.dataSource?.vimeoVideoHash;
        final urls = await _cachedStreams(
          () => VideoApis.getVimeoVideoQualityUrls(videoId, hash, onThumbnail: _onThumbnail),
        );
        return _pickQualityUrl(urls);
      case AllPlayerType.vimeoPrivateVideos:
        final videoId = playVideoFrom.dataSource?.vimeoVideoId ?? playVideoFrom.dataSource!;
        final urls = await _cachedStreams(
          () => VideoApis.getVimeoPrivateVideoQualityUrls(videoId, playVideoFrom.httpHeaders),
        );
        return _pickQualityUrl(urls);
      case AllPlayerType.dailymotion:
        final videoId = playVideoFrom.dataSource?.dailymotionVideoId ?? playVideoFrom.dataSource!;
        final token = playVideoFrom.token;
        final urls = await _cachedStreams(
          () => token != null
              ? VideoApis.getDailymotionVideoQualityUrls(videoId, token)
              : VideoApis.getDailymotionVideoQualityM3U8Urls(videoId, onThumbnail: _onThumbnail),
        );
        return _pickQualityUrl(urls);
      case AllPlayerType.asset:
      case AllPlayerType.file:
      case AllPlayerType.youtubeIframe:
        return playVideoFrom.dataSource ?? '';
    }
  }

  String _pickQualityUrl(List<VideoQalityUrls> urls) {
    final sorted = List<VideoQalityUrls>.from(urls)
      ..removeWhere((e) => e.quality == 240 || (kIsWeb && e.quality == 144))
      ..sort((a, b) => a.quality.compareTo(b.quality));

    if (sorted.isEmpty) {
      throw Exception('Video quality list cannot be empty');
    }

    final fallback = sorted.first;
    VideoQalityUrls? picked;
    final priority = [
      if (playerConfig.rememberPreferences && _prefs.quality != null) _prefs.quality!,
      ...playerConfig.videoQualityPriority,
    ];
    for (final q in priority) {
      picked = sorted.firstWhere((e) => e.quality == q, orElse: () => fallback);
      if (picked != fallback) break;
    }
    picked ??= fallback;

    emit(state.copyWith(
      availableQualities: sorted,
      currentQuality: picked.quality,
      playingVideoUrl: picked.url,
    ));
    return picked.url;
  }

  void _videoListener() {
    if (isClosed || videoCtr == null) return;
    final value = videoCtr!.value;
    if (!value.isInitialized) return;

    final AllPlayerStatus currentStatus;
    if (value.hasError) {
      currentStatus = AllPlayerStatus.error;
    } else if (value.isBuffering) {
      currentStatus = AllPlayerStatus.loading;
    } else if (value.isPlaying) {
      currentStatus = AllPlayerStatus.playing;
    } else {
      currentStatus = AllPlayerStatus.paused;
    }

    if (currentStatus == AllPlayerStatus.playing) _savePosition();

    emit(state.copyWith(
      playerStatus: currentStatus,
      videoPosition: value.position,
      videoDuration: value.duration,
      volume: value.volume,
      isMute: value.volume == 0,
      isLooping: value.isLooping,
      errorMessage: value.errorDescription,
    ));
  }

  /// Persists the position (throttled unless [force]) so the video can resume.
  void _savePosition({bool force = false}) {
    final key = _cacheKey;
    final value = videoCtr?.value;
    if (key == null || !playerConfig.resumePlayback || value == null || !value.isInitialized) {
      return;
    }

    final now = DateTime.now();
    if (!force && now.difference(_lastPositionSave) < _positionSaveInterval) return;
    _lastPositionSave = now;
    unawaited(AllPlayerCache.savePosition(key, value.position, value.duration));
  }

  void _savePrefs(AllPlayerPrefs prefs) {
    _prefs = prefs;
    if (_cacheKey != null && playerConfig.rememberPreferences) {
      unawaited(AllPlayerCache.savePrefs(prefs));
    }
  }

  Future<void> play() async {
    if (isIframe) {
      youtubeIframeController?.playVideo();
      emit(state.copyWith(playerStatus: AllPlayerStatus.playing));
    } else {
      await videoCtr?.play();
      if (playerConfig.wakelockEnabled) {
        unawaited(WakelockPlus.enable().catchError((_) {}));
      }
      isShowOverlay(true);
      isShowOverlay(false, delay: const Duration(seconds: 1));
    }
  }

  Future<void> pause() async {
    if (isIframe) {
      youtubeIframeController?.pauseVideo();
      emit(state.copyWith(playerStatus: AllPlayerStatus.paused));
    } else {
      await videoCtr?.pause();
      _savePosition(force: true);
      if (playerConfig.wakelockEnabled) {
        unawaited(WakelockPlus.disable().catchError((_) {}));
      }
      isShowOverlay(true);
    }
  }

  void togglePlayPause() {
    isVideoPlaying ? pause() : play();
  }

  Future<void> seekTo(Duration moment) async {
    if (isIframe) {
      await youtubeIframeController?.seekTo(seconds: moment.inSeconds.toDouble());
    } else {
      await videoCtr?.seekTo(moment);
    }
  }

  Future<void> seekForward(Duration duration) async {
    await seekTo(currentVideoPosition + duration);
  }

  Future<void> seekBackward(Duration duration) async {
    await seekTo(currentVideoPosition - duration);
  }

  Future<void> setVolume(double volume) async {
    if (isIframe) {
      if (volume <= 0) {
        await youtubeIframeController?.mute();
      } else {
        await youtubeIframeController?.unMute();
      }
    } else {
      await videoCtr?.setVolume(volume);
    }
    emit(state.copyWith(
      volume: volume,
      isMute: volume <= 0,
    ));
    _savePrefs(_prefs.copyWith(volume: volume));
  }

  Future<void> mute() async => setVolume(0);

  Future<void> unMute() async => setVolume(1);

  Future<void> toggleVolume() async {
    state.isMute ? await unMute() : await mute();
  }

  void setVideoPlayback(String speed, {bool persist = true}) {
    final double pickedSpeed;
    if (speed == 'Normal' || speed == '1x') {
      pickedSpeed = 1.0;
    } else {
      pickedSpeed = double.tryParse(speed.split('x').first) ?? 1.0;
    }
    if (isIframe) {
      youtubeIframeController?.setPlaybackRate(pickedSpeed);
    } else {
      videoCtr?.setPlaybackSpeed(pickedSpeed);
    }
    emit(state.copyWith(playbackSpeed: speed));
    if (persist) _savePrefs(_prefs.copyWith(speed: speed));
  }

  Future<void> setLooping(bool isLooped) async {
    if (!isIframe) {
      await videoCtr?.setLooping(isLooped);
    }
    emit(state.copyWith(isLooping: isLooped));
  }

  Future<void> toggleLooping() async => setLooping(!state.isLooping);

  Future<void> changeVideoQuality(int? quality) async {
    if (quality == null || quality == state.currentQuality) return;
    final target = state.availableQualities.firstWhere(
      (e) => e.quality == quality,
      orElse: () => state.availableQualities.first,
    );

    final currentPosition = state.videoPosition;
    final currentSpeed = state.playbackSpeed;

    emit(state.copyWith(
      playerStatus: AllPlayerStatus.loading,
      currentQuality: target.quality,
      playingVideoUrl: target.url,
    ));

    videoCtr?.removeListener(_videoListener);
    await videoCtr?.dispose();

    videoCtr = _createNetworkController(target.url, quality: target.quality);
    await _initializeWithFallback(target.url, quality: target.quality);
    videoCtr?.addListener(_videoListener);
    await videoCtr?.seekTo(currentPosition);
    setVideoPlayback(currentSpeed);
    await play();

    _savePrefs(_prefs.copyWith(quality: target.quality));
    onVideoQualityChanged?.call();
  }

  void onLeftDoubleTap({int? seconds}) {
    isShowOverlay(true);
    _leftDoubleTapTimer?.cancel();
    _rightDoubleTapTimer?.cancel();

    final duration = (seconds ?? doubleTapForwardSeconds);
    final accumulated = state.leftDoubleTapDuration + duration;

    seekBackward(Duration(seconds: duration));
    emit(state.copyWith(
      isLeftDbTapIconVisible: true,
      isRightDbTapIconVisible: false,
      leftDoubleTapDuration: accumulated,
    ));

    _leftDoubleTapTimer = Timer(const Duration(milliseconds: 600), () {
      if (isClosed) return;
      emit(state.copyWith(
        isLeftDbTapIconVisible: false,
        leftDoubleTapDuration: 0,
      ));
      if (isVideoPlaying) {
        isShowOverlay(false);
      }
    });
  }

  void onRightDoubleTap({int? seconds}) {
    isShowOverlay(true);
    _rightDoubleTapTimer?.cancel();
    _leftDoubleTapTimer?.cancel();

    final duration = (seconds ?? doubleTapForwardSeconds);
    final accumulated = state.rightDoubleTapDuration + duration;

    seekForward(Duration(seconds: duration));
    emit(state.copyWith(
      isRightDbTapIconVisible: true,
      isLeftDbTapIconVisible: false,
      rightDoubleTapDuration: accumulated,
    ));

    _rightDoubleTapTimer = Timer(const Duration(milliseconds: 600), () {
      if (isClosed) return;
      emit(state.copyWith(
        isRightDbTapIconVisible: false,
        rightDoubleTapDuration: 0,
      ));
      if (isVideoPlaying) {
        isShowOverlay(false);
      }
    });
  }

  void isShowOverlay(bool val, {Duration? delay}) {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(delay ?? Duration.zero, () {
      if (isClosed) return;
      if (state.isOverlayVisible != val) {
        emit(state.copyWith(isOverlayVisible: val));
      }
    });
  }

  void toggleVideoOverlay() {
    if (!state.isOverlayVisible) {
      emit(state.copyWith(isOverlayVisible: true));
      _overlayTimer?.cancel();
      _overlayTimer = Timer(const Duration(seconds: 3), () {
        if (!isClosed && isVideoPlaying) {
          emit(state.copyWith(isOverlayVisible: false));
        }
      });
    } else {
      emit(state.copyWith(isOverlayVisible: false));
    }
  }

  void showOverlay() => isShowOverlay(true);

  void hideOverlay() => isShowOverlay(false);

  void onOverlayHover() {
    if (kIsWeb) {
      _hoverOverlayTimer?.cancel();
      isShowOverlay(true);
      _hoverOverlayTimer = Timer(const Duration(seconds: 3), () {
        if (!isClosed && isVideoPlaying) {
          isShowOverlay(false);
        }
      });
    }
  }

  void onOverlayHoverExit() {
    if (kIsWeb) {
      isShowOverlay(false);
    }
  }

  Future<void> enableFullScreen(BuildContext context) async {
    if (state.isFullScreen) return;
    if (kIsWeb) {
      uni_html.document.documentElement?.requestFullscreen();
    }

    if (onToggleFullScreen != null) {
      await onToggleFullScreen!(true);
    } else {
      await Future.wait([
        SystemChrome.setPreferredOrientations([
          if (!kIsWeb) DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      ]);
    }

    emit(state.copyWith(isFullScreen: true));

    await Navigator.of(context).push(
      PageRouteBuilder<dynamic>(
        fullscreenDialog: true,
        pageBuilder: (ctx, _, __) => FullScreenView(controller: this),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (ctx, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    if (state.isFullScreen && context.mounted) {
      await disableFullScreen(context, enablePop: false);
    }
  }

  Future<void> disableFullScreen(
    BuildContext context, {
    bool enablePop = true,
  }) async {
    if (!state.isFullScreen) return;
    if (kIsWeb) {
      uni_html.document.exitFullscreen();
    }

    if (onToggleFullScreen != null) {
      await onToggleFullScreen!(false);
    } else {
      await Future.wait([
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
        if (defaultTargetPlatform != TargetPlatform.iOS) ...[
          SystemChrome.setPreferredOrientations(DeviceOrientation.values),
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          ),
        ],
      ]);
    }

    emit(state.copyWith(isFullScreen: false));
    if (enablePop && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void toggleFullScreen(BuildContext context) {
    state.isFullScreen ? disableFullScreen(context) : enableFullScreen(context);
  }

  void onKeyBoardEvents({
    required KeyEvent event,
    required BuildContext context,
  }) {
    if (kIsWeb) {
      if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space)) {
        togglePlayPause();
      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyM)) {
        toggleVolume();
      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowLeft)) {
        onLeftDoubleTap();
      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowRight)) {
        onRightDoubleTap();
      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyF)) {
        toggleFullScreen(context);
      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.escape)) {
        if (state.isFullScreen) {
          disableFullScreen(context);
        }
      }
    }
  }

  String calculateVideoDuration(Duration duration) {
    final totalHour = duration.inHours == 0 ? '' : '${duration.inHours}:';
    final totalMinute = duration.toString().split(':')[1];
    final totalSeconds = (duration - Duration(minutes: duration.inMinutes))
        .inSeconds
        .toString()
        .padLeft(2, '0');
    return '$totalHour$totalMinute:$totalSeconds';
  }

  Future<void> changeVideo({
    required PlayVideoFrom playVideoFrom,
    AllPlayerConfig playerConfig = const AllPlayerConfig(),
  }) async {
    videoCtr?.removeListener(_videoListener);
    await videoCtr?.dispose();
    videoCtr = null;
    youtubeIframeController?.close();
    youtubeIframeController = null;

    this.playVideoFrom = playVideoFrom;
    this.playerConfig = playerConfig;

    emit(const AllPlayerState());
    await initialise();
  }

  void addListener(VoidCallback listener) {
    videoCtr?.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    videoCtr?.removeListener(listener);
  }

  @override
  Future<void> close() {
    _overlayTimer?.cancel();
    _leftDoubleTapTimer?.cancel();
    _rightDoubleTapTimer?.cancel();
    _hoverOverlayTimer?.cancel();
    _savePosition(force: true);
    videoCtr?.removeListener(_videoListener);
    videoCtr?.dispose();
    youtubeIframeController?.close();
    if (playerConfig.wakelockEnabled) {
      unawaited(WakelockPlus.disable().catchError((_) {}));
    }
    return super.close();
  }
}
