part of 'package:all_player/src/all_player.dart';

class _WebOverlay extends StatelessWidget {
  final String? tag;
  const _WebOverlay({
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    const overlayColor = Colors.black38;
    final playerCtr = context.read<AllPlayerController>();
    return Stack(
      children: [
        Positioned.fill(
          child: _VideoGestureDetector(
            tag: tag,
            onTap: playerCtr.togglePlayPause,
            onDoubleTap: () => playerCtr.toggleFullScreen(context),
            child: const ColoredBox(
              color: overlayColor,
              child: SizedBox.expand(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: _WebOverlayBottomControllers(tag: tag),
        ),
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: IgnorePointer(
                  child: DoubleTapIcon(
                    onDoubleTap: () {},
                    tag: tag,
                    isForward: false,
                    iconOnly: true,
                  ),
                ),
              ),
              Expanded(
                child: IgnorePointer(
                  child: DoubleTapIcon(
                    onDoubleTap: () {},
                    tag: tag,
                    isForward: true,
                    iconOnly: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        IgnorePointer(child: playerCtr.videoTitle ?? const SizedBox()),
      ],
    );
  }
}

class _WebOverlayBottomControllers extends StatelessWidget {
  final String? tag;

  const _WebOverlayBottomControllers({
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    const durationTextStyle = TextStyle(color: Colors.white70);
    const itemColor = Colors.white;

    return MouseRegion(
      onHover: (event) => playerCtr.onOverlayHover(),
      onExit: (event) => playerCtr.onOverlayHoverExit(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AllProgressBar(
              controller: playerCtr,
              progressBarConfig: playerCtr.progressBarConfig,
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: BlocBuilder<AllPlayerController, AllPlayerState>(
                      builder: (context, state) {
                        return Row(
                          children: [
                            _AnimatedPlayPauseIcon(tag: tag),
                            MaterialIconButton(
                              toolTipMesg: state.isMute
                                  ? playerCtr.playerLabels.unmute ??
                                      'Unmute${kIsWeb ? ' (m)' : ''}'
                                  : playerCtr.playerLabels.mute ??
                                      'Mute${kIsWeb ? ' (m)' : ''}',
                              color: itemColor,
                              onPressed: playerCtr.toggleVolume,
                              child: Icon(
                                state.isMute
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  playerCtr.calculateVideoDuration(state.videoPosition),
                                  style: durationTextStyle,
                                ),
                                const Text(' / ', style: durationTextStyle),
                                Text(
                                  playerCtr.calculateVideoDuration(state.videoDuration),
                                  style: durationTextStyle,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: BlocBuilder<AllPlayerController, AllPlayerState>(
                      builder: (context, state) {
                        return Row(
                          children: [
                            _WebSettingsDropdown(tag: tag),
                            MaterialIconButton(
                              toolTipMesg: state.isFullScreen
                                  ? playerCtr.playerLabels.exitFullScreen ??
                                      'Exit full screen${kIsWeb ? ' (f)' : ''}'
                                  : playerCtr.playerLabels.fullscreen ??
                                      'Fullscreen${kIsWeb ? ' (f)' : ''}',
                              color: itemColor,
                              onPressed: () {
                                if (state.isOverlayVisible) {
                                  playerCtr.toggleFullScreen(context);
                                } else {
                                  playerCtr.toggleVideoOverlay();
                                }
                              },
                              child: Icon(
                                state.isFullScreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
