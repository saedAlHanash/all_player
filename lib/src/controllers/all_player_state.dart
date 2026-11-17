import '../models/vimeo_models.dart';
import '../utils/enums.dart';

class AllPlayerState {
  final AllPlayerStatus playerStatus;
  final Duration videoPosition;
  final Duration videoDuration;
  final bool isFullScreen;
  final bool isOverlayVisible;
  final bool isMute;
  final double volume;
  final String playbackSpeed;
  final bool isLooping;
  final int? currentQuality;
  final List<VideoQalityUrls> availableQualities;
  final int leftDoubleTapDuration;
  final int rightDoubleTapDuration;
  final bool isLeftDbTapIconVisible;
  final bool isRightDbTapIconVisible;
  final String? errorMessage;
  final String? playingVideoUrl;
  final String? thumbnailUrl;

  const AllPlayerState({
    this.playerStatus = AllPlayerStatus.loading,
    this.videoPosition = Duration.zero,
    this.videoDuration = Duration.zero,
    this.isFullScreen = false,
    this.isOverlayVisible = true,
    this.isMute = false,
    this.volume = 1.0,
    this.playbackSpeed = '1x',
    this.isLooping = false,
    this.currentQuality,
    this.availableQualities = const [],
    this.leftDoubleTapDuration = 0,
    this.rightDoubleTapDuration = 0,
    this.isLeftDbTapIconVisible = false,
    this.isRightDbTapIconVisible = false,
    this.errorMessage,
    this.playingVideoUrl,
    this.thumbnailUrl,
  });

  AllPlayerState copyWith({
    AllPlayerStatus? playerStatus,
    Duration? videoPosition,
    Duration? videoDuration,
    bool? isFullScreen,
    bool? isOverlayVisible,
    bool? isMute,
    double? volume,
    String? playbackSpeed,
    bool? isLooping,
    int? currentQuality,
    List<VideoQalityUrls>? availableQualities,
    int? leftDoubleTapDuration,
    int? rightDoubleTapDuration,
    bool? isLeftDbTapIconVisible,
    bool? isRightDbTapIconVisible,
    String? errorMessage,
    String? playingVideoUrl,
    String? thumbnailUrl,
  }) {
    return AllPlayerState(
      playerStatus: playerStatus ?? this.playerStatus,
      videoPosition: videoPosition ?? this.videoPosition,
      videoDuration: videoDuration ?? this.videoDuration,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isMute: isMute ?? this.isMute,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isLooping: isLooping ?? this.isLooping,
      currentQuality: currentQuality ?? this.currentQuality,
      availableQualities: availableQualities ?? this.availableQualities,
      leftDoubleTapDuration: leftDoubleTapDuration ?? this.leftDoubleTapDuration,
      rightDoubleTapDuration: rightDoubleTapDuration ?? this.rightDoubleTapDuration,
      isLeftDbTapIconVisible: isLeftDbTapIconVisible ?? this.isLeftDbTapIconVisible,
      isRightDbTapIconVisible: isRightDbTapIconVisible ?? this.isRightDbTapIconVisible,
      errorMessage: errorMessage ?? this.errorMessage,
      playingVideoUrl: playingVideoUrl ?? this.playingVideoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}
