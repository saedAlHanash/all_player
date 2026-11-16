import '../utils/enums.dart';
import '../widgets/all_progress_bar.dart';

class OverLayOptions {
  final AllPlayerStatus playerStatus;
  final Duration videoDuration;
  final Duration videoPosition;
  final bool isFullScreen;
  final bool isLooping;
  final bool isOverlayVisible;
  final bool isMute;
  final bool autoPlay;
  final String currentVideoPlaybackSpeed;
  final List<String> videoPlayBackSpeeds;
  final AllPlayerType videoPlayerType;
  final AllProgressBar progressBar;

  OverLayOptions({
    required this.playerStatus,
    required this.videoDuration,
    required this.videoPosition,
    required this.isFullScreen,
    required this.isLooping,
    required this.isOverlayVisible,
    required this.isMute,
    required this.autoPlay,
    required this.currentVideoPlaybackSpeed,
    required this.videoPlayBackSpeeds,
    required this.videoPlayerType,
    required this.progressBar,
  });
}
