part of 'package:all_player/src/all_player.dart';

class _MobileOverlay extends StatelessWidget {
  final String? tag;

  const _MobileOverlay({
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    const overlayColor = Colors.black38;
    const itemColor = Colors.white;
    final playerCtr = context.read<AllPlayerController>();
    return Stack(
      alignment: Alignment.center,
      children: [
        _VideoGestureDetector(
          tag: tag,
          child: ColoredBox(
            color: overlayColor,
            child: Row(
              children: [
                Expanded(
                  child: DoubleTapIcon(
                    tag: tag,
                    isForward: false,
                    height: double.maxFinite,
                    onDoubleTap: _isRtl()
                        ? playerCtr.onRightDoubleTap
                        : playerCtr.onLeftDoubleTap,
                  ),
                ),
                SizedBox(
                  height: double.infinity,
                  child: Center(
                    child: _AnimatedPlayPauseIcon(tag: tag, size: 42),
                  ),
                ),
                Expanded(
                  child: DoubleTapIcon(
                    isForward: true,
                    tag: tag,
                    height: double.maxFinite,
                    onDoubleTap: _isRtl()
                        ? playerCtr.onLeftDoubleTap
                        : playerCtr.onRightDoubleTap,
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: IgnorePointer(
                  child: playerCtr.videoTitle ?? const SizedBox(),
                ),
              ),
              BlocBuilder<AllPlayerController, AllPlayerState>(
                buildWhen: (prev, curr) => prev.isOverlayVisible != curr.isOverlayVisible,
                builder: (context, state) {
                  return MaterialIconButton(
                    toolTipMesg: playerCtr.playerLabels.settings,
                    color: itemColor,
                    onPressed: () {
                      if (state.isOverlayVisible) {
                        _bottomSheet(context, playerCtr);
                      } else {
                        playerCtr.toggleVideoOverlay();
                      }
                    },
                    child: const Icon(Icons.more_vert_rounded),
                  );
                },
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: _MobileOverlayBottomControllers(tag: tag),
        ),
      ],
    );
  }

  bool _isRtl() {
    final Locale locale = WidgetsBinding.instance.platformDispatcher.locale;
    final langs = [
      'ar', // Arabic
      'fa', // Farsi
      'he', // Hebrew
      'ps', // Pashto
      'ur', // Urdu
    ];
    for (int i = 0; i < langs.length; i++) {
      final lang = langs[i];
      if (locale.toString().contains(lang)) {
        return true;
      }
    }
    return false;
  }

  void _bottomSheet(BuildContext context, AllPlayerController playerCtr) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: playerCtr,
        child: SafeArea(child: _MobileBottomSheet(tag: tag)),
      ),
    );
  }
}
