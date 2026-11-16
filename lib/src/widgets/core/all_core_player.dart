part of 'package:all_player/src/all_player.dart';

class _AllCoreVideoPlayer extends StatefulWidget {
  final VideoPlayerController videoPlayerCtr;
  final double videoAspectRatio;
  final String? tag;

  const _AllCoreVideoPlayer({
    required this.videoPlayerCtr,
    required this.videoAspectRatio,
    this.tag,
  });

  @override
  State<_AllCoreVideoPlayer> createState() => _AllCoreVideoPlayerState();
}

class _AllCoreVideoPlayerState extends State<_AllCoreVideoPlayer> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (event) => playerCtr.onKeyBoardEvents(
        event: event,
        context: context,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.videoAspectRatio,
              child: VideoPlayer(widget.videoPlayerCtr),
            ),
          ),
          BlocBuilder<AllPlayerController, AllPlayerState>(
            buildWhen: (prev, curr) =>
                prev.playerStatus != curr.playerStatus ||
                prev.videoPosition != curr.videoPosition,
            builder: (context, state) {
              if (playerCtr.videoThumbnail == null) {
                return const SizedBox();
              }
              if (state.playerStatus == AllPlayerStatus.paused &&
                  state.videoPosition == Duration.zero) {
                return SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: child,
                    ),
                    tween: Tween<double>(begin: 0.7, end: 1),
                    duration: const Duration(milliseconds: 400),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        image: playerCtr.videoThumbnail,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          _VideoOverlays(tag: widget.tag),
          IgnorePointer(
            child: BlocBuilder<AllPlayerController, AllPlayerState>(
              buildWhen: (prev, curr) => prev.playerStatus != curr.playerStatus,
              builder: (context, state) {
                final loadingWidget = playerCtr.onLoading?.call(context) ??
                    const Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    );

                if (kIsWeb) {
                  switch (state.playerStatus) {
                    case AllPlayerStatus.loading:
                      return loadingWidget;
                    case AllPlayerStatus.paused:
                      return const Center(
                        child: Icon(
                          Icons.play_arrow,
                          size: 45,
                          color: Colors.white,
                        ),
                      );
                    case AllPlayerStatus.playing:
                      return Center(
                        child: TweenAnimationBuilder<double>(
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: child,
                          ),
                          tween: Tween<double>(begin: 1, end: 0),
                          duration: const Duration(seconds: 1),
                          child: const Icon(
                            Icons.pause,
                            size: 45,
                            color: Colors.white,
                          ),
                        ),
                      );
                    case AllPlayerStatus.error:
                      return const SizedBox();
                  }
                } else {
                  if (state.playerStatus == AllPlayerStatus.loading) {
                    return loadingWidget;
                  }
                  return const SizedBox();
                }
              },
            ),
          ),
          if (!kIsWeb)
            BlocBuilder<AllPlayerController, AllPlayerState>(
              buildWhen: (prev, curr) =>
                  prev.isFullScreen != curr.isFullScreen ||
                  prev.isOverlayVisible != curr.isOverlayVisible,
              builder: (context, state) {
                if (state.isFullScreen || state.isOverlayVisible || !playerCtr.alwaysShowProgressBar) {
                  return const SizedBox();
                }
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: AllProgressBar(
                    controller: playerCtr,
                    alignment: Alignment.bottomCenter,
                    progressBarConfig: playerCtr.progressBarConfig,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
