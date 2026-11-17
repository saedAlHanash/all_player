class AllPlayerConfig {
  final bool autoPlay;
  final bool isLooping;
  final bool wakelockEnabled;

  /// Persist stream urls, thumbnail url and resume position per video
  /// (through m_cubit's `CachingService`, which must be initialised by the app).
  final bool cacheEnabled;

  /// Cache the video bytes on disk for supported sources. Only has an effect
  /// after `AllPlayerVideoCache.init()` was called.
  final bool cacheVideo;

  /// Continue from the last watched position (needs [cacheEnabled]).
  final bool resumePlayback;

  /// Remember the quality, speed and volume the user picked (needs [cacheEnabled]).
  final bool rememberPreferences;

  /// Initial video quality priority. The first available option will be used,
  /// from start to the end of this list. If all options informed are not
  /// available or if nothing is provided, 360p is used.
  ///
  /// Default value is [1080, 720, 360]
  final List<int> videoQualityPriority;

  const AllPlayerConfig({
    this.autoPlay = true,
    this.isLooping = false,
    this.wakelockEnabled = true,
    this.cacheEnabled = true,
    this.cacheVideo = true,
    this.resumePlayback = false,
    this.rememberPreferences = true,
    this.videoQualityPriority = const [1080, 720, 360],
  });

  AllPlayerConfig copyWith({
    bool? autoPlay,
    bool? isLooping,
    bool? wakelockEnabled,
    bool? cacheEnabled,
    bool? cacheVideo,
    bool? resumePlayback,
    bool? rememberPreferences,
    List<int>? videoQualityPriority,
  }) {
    return AllPlayerConfig(
      autoPlay: autoPlay ?? this.autoPlay,
      isLooping: isLooping ?? this.isLooping,
      wakelockEnabled: wakelockEnabled ?? this.wakelockEnabled,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
      cacheVideo: cacheVideo ?? this.cacheVideo,
      resumePlayback: resumePlayback ?? this.resumePlayback,
      rememberPreferences: rememberPreferences ?? this.rememberPreferences,
      videoQualityPriority: videoQualityPriority ?? this.videoQualityPriority,
    );
  }
}
