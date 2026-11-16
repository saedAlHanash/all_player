part of 'package:all_player/src/all_player.dart';

class _VideoOverlays extends StatelessWidget {
  final String? tag;

  const _VideoOverlays({
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    if (playerCtr.overlayBuilder != null) {
      return BlocBuilder<AllPlayerController, AllPlayerState>(
        builder: (context, state) {
          final progressBar = AllProgressBar(
            controller: playerCtr,
            progressBarConfig: playerCtr.progressBarConfig,
          );
          final overlayOptions = OverLayOptions(
            playerStatus: state.playerStatus,
            videoDuration: state.videoDuration,
            videoPosition: state.videoPosition,
            isFullScreen: state.isFullScreen,
            isLooping: state.isLooping,
            isOverlayVisible: state.isOverlayVisible,
            isMute: state.isMute,
            autoPlay: playerCtr.playerConfig.autoPlay,
            currentVideoPlaybackSpeed: state.playbackSpeed,
            videoPlayBackSpeeds: AllPlayerController.videoPlaybackSpeeds,
            videoPlayerType: playerCtr.videoPlayerType,
            progressBar: progressBar,
          );

          return playerCtr.overlayBuilder!(overlayOptions);
        },
      );
    } else {
      return BlocBuilder<AllPlayerController, AllPlayerState>(
        buildWhen: (prev, curr) => prev.isOverlayVisible != curr.isOverlayVisible,
        builder: (context, state) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: state.isOverlayVisible ? 1 : 0,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                if (!kIsWeb) _MobileOverlay(tag: tag),
                if (kIsWeb) _WebOverlay(tag: tag),
              ],
            ),
          );
        },
      );
    }
  }
}
