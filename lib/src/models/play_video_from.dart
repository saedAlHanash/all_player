import 'dart:io';

import '../../all_player.dart';

class PlayVideoFrom {
  final String? dataSource;
  final String? hash;
  final String? token;
  final AllPlayerType playerType;
  final VideoFormat? formatHint;
  final String? package;
  final File? file;
  final List<VideoQalityUrls>? videoQualityUrls;
  final Future<ClosedCaptionFile>? closedCaptionFile;
  final VideoPlayerOptions? videoPlayerOptions;
  final Map<String, String> httpHeaders;
  final bool live;
  final YoutubePlayerParams? youtubeParams;

  /// Stable id used as the cache key for sources that have no natural id
  /// (e.g. signed network urls that change on every request).
  final String? cacheId;

  /// Key under which metadata (stream urls, thumbnail, resume position) is
  /// cached, or `null` when this source cannot be cached.
  String? get cacheKey {
    final id = cacheId ?? dataSource;
    if (id == null || id.isEmpty) return null;
    switch (playerType) {
      case AllPlayerType.youtube:
      case AllPlayerType.youtubeIframe:
        return 'youtube:$id';
      case AllPlayerType.vimeo:
      case AllPlayerType.vimeoPrivateVideos:
        return 'vimeo:$id';
      case AllPlayerType.dailymotion:
        return 'dailymotion:$id';
      case AllPlayerType.network:
        return 'url:$id';
      case AllPlayerType.asset:
        return 'asset:$id';
      case AllPlayerType.networkQualityUrls:
        return cacheId == null ? null : 'urls:$cacheId';
      case AllPlayerType.file:
        return file == null ? null : 'file:${file!.path}';
    }
  }

  const PlayVideoFrom._({
    required this.playerType,
    this.cacheId,
    this.live = false,
    this.dataSource,
    this.token,
    this.hash,
    this.formatHint,
    this.package,
    this.file,
    this.videoQualityUrls,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.httpHeaders = const {},
    this.youtubeParams,
  });

  /// Automatically detects the platform (YouTube, Vimeo, Dailymotion, Network)
  /// from the URL or video ID.
  ///
  /// For YouTube, [preferYoutubeMode] specifies whether to prefer the
  /// WebView iframe player or the direct stream player (defaults to [YoutubePlayMode.iframe]).
  factory PlayVideoFrom.auto(
    String dataSource, {
    YoutubePlayMode preferYoutubeMode = YoutubePlayMode.iframe,
    YoutubePlayerParams? youtubeParams,
    bool live = false,
    String? hash,
    String? token,
    String? package,
    String? cacheId,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    final platform = dataSource.detectVideoPlatform;
    switch (platform) {
      case VideoPlatform.youtube:
        final videoId = dataSource.youtubeVideoId ?? dataSource;
        if (preferYoutubeMode.isIframe) {
          return PlayVideoFrom.youtubeIframe(
            videoId,
            params: youtubeParams,
          );
        } else {
          return PlayVideoFrom.youtube(
            videoId,
            live: live,
            formatHint: formatHint,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
            httpHeaders: httpHeaders,
          );
        }
      case VideoPlatform.vimeo:
        final videoId = dataSource.vimeoVideoId ?? dataSource;
        final videoHash = hash ?? dataSource.vimeoVideoHash;
        return PlayVideoFrom.vimeo(
          videoId,
          hash: videoHash,
          formatHint: formatHint,
          closedCaptionFile: closedCaptionFile,
          videoPlayerOptions: videoPlayerOptions,
          httpHeaders: httpHeaders,
        );
      case VideoPlatform.dailymotion:
        final videoId = dataSource.dailymotionVideoId ?? dataSource;
        return PlayVideoFrom.dailymotion(
          videoId,
          token: token,
          formatHint: formatHint,
          closedCaptionFile: closedCaptionFile,
          videoPlayerOptions: videoPlayerOptions,
          httpHeaders: httpHeaders,
        );
      case VideoPlatform.network:
      case VideoPlatform.unknown:
        return PlayVideoFrom.network(
          dataSource,
          cacheId: cacheId,
          formatHint: formatHint,
          closedCaptionFile: closedCaptionFile,
          videoPlayerOptions: videoPlayerOptions,
          httpHeaders: httpHeaders,
        );
    }
  }

  factory PlayVideoFrom.network(
    String dataSource, {
    String? cacheId,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    return PlayVideoFrom._(
      playerType: AllPlayerType.network,
      dataSource: dataSource,
      cacheId: cacheId,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }

  factory PlayVideoFrom.asset(
    String dataSource, {
    String? package,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
  }) {
    return PlayVideoFrom._(
      playerType: AllPlayerType.asset,
      dataSource: dataSource,
      package: package,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  ///File Doesnot support web apps
  ///[file] is `File` Datatype import it from `dart:io`
  factory PlayVideoFrom.file(
    File file, {
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
  }) {
    return PlayVideoFrom._(
      file: file,
      playerType: AllPlayerType.file,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  factory PlayVideoFrom.vimeo(
    String dataSource, {
    String? hash,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    final videoId = dataSource.vimeoVideoId ?? dataSource;
    final videoHash = hash ?? dataSource.vimeoVideoHash;
    return PlayVideoFrom._(
      playerType: AllPlayerType.vimeo,
      dataSource: videoId,
      hash: videoHash,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }

  factory PlayVideoFrom.vimeoPrivateVideos(
    String dataSource, {
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    final videoId = dataSource.vimeoVideoId ?? dataSource;
    return PlayVideoFrom._(
      playerType: AllPlayerType.vimeoPrivateVideos,
      dataSource: videoId,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }

  factory PlayVideoFrom.youtube(
    String dataSource, {
    bool live = false,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    final videoId = dataSource.youtubeVideoId ?? dataSource;
    return PlayVideoFrom._(
      live: live,
      playerType: AllPlayerType.youtube,
      dataSource: videoId,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }

  /// Alias for `PlayVideoFrom.youtube` (Direct stream player)
  factory PlayVideoFrom.youtubePlayer(
    String dataSource, {
    bool live = false,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    return PlayVideoFrom.youtube(
      dataSource,
      live: live,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }

  /// Plays YouTube video using the official YouTube iframe player (WebView)
  factory PlayVideoFrom.youtubeIframe(
    String videoIdOrUrl, {
    YoutubePlayerParams? params,
  }) {
    final videoId = videoIdOrUrl.youtubeVideoId ?? videoIdOrUrl;
    return PlayVideoFrom._(
      playerType: AllPlayerType.youtubeIframe,
      dataSource: videoId,
      youtubeParams: params,
    );
  }

  factory PlayVideoFrom.dailymotion(
    String dataSource, {
    String? token,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    final videoId = dataSource.dailymotionVideoId ?? dataSource;
    return PlayVideoFrom._(
      playerType: AllPlayerType.dailymotion,
      dataSource: videoId,
      token: token,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }

  factory PlayVideoFrom.networkQualityUrls({
    required List<VideoQalityUrls> videoUrls,
    String? cacheId,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    return PlayVideoFrom._(
      playerType: AllPlayerType.networkQualityUrls,
      cacheId: cacheId,
      videoQualityUrls: videoUrls,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }
}
