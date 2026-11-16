part of 'package:all_player/src/all_player.dart';

class _MobileBottomSheet extends StatelessWidget {
  final String? tag;

  const _MobileBottomSheet({
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    return BlocBuilder<AllPlayerController, AllPlayerState>(
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.availableQualities.isNotEmpty)
            _bottomSheetTiles(
              title: playerCtr.playerLabels.quality,
              icon: Icons.video_settings_rounded,
              subText: '${state.currentQuality ?? 0}p',
              onTap: () {
                Navigator.of(context).pop();
                Timer(const Duration(milliseconds: 100), () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) => BlocProvider.value(
                      value: playerCtr,
                      child: SafeArea(
                        child: _VideoQualitySelectorMob(
                          tag: tag,
                          onTap: null,
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          _bottomSheetTiles(
            title: playerCtr.playerLabels.loopVideo,
            icon: Icons.loop_rounded,
            subText: state.isLooping
                ? playerCtr.playerLabels.optionEnabled
                : playerCtr.playerLabels.optionDisabled,
            onTap: () {
              Navigator.of(context).pop();
              playerCtr.toggleLooping();
            },
          ),
          _bottomSheetTiles(
            title: playerCtr.playerLabels.playbackSpeed,
            icon: Icons.slow_motion_video_rounded,
            subText: state.playbackSpeed,
            onTap: () {
              Navigator.of(context).pop();
              Timer(const Duration(milliseconds: 100), () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => BlocProvider.value(
                    value: playerCtr,
                    child: SafeArea(
                      child: _VideoPlaybackSelectorMob(
                        tag: tag,
                        onTap: null,
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  ListTile _bottomSheetTiles({
    required String title,
    required IconData icon,
    String? subText,
    void Function()? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      onTap: onTap,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(title),
            if (subText != null) const SizedBox(width: 6),
            if (subText != null)
              const SizedBox(
                height: 4,
                width: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (subText != null) const SizedBox(width: 6),
            if (subText != null)
              Text(
                subText,
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoQualitySelectorMob extends StatelessWidget {
  final void Function()? onTap;
  final String? tag;

  const _VideoQualitySelectorMob({
    required this.onTap,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    return BlocBuilder<AllPlayerController, AllPlayerState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: state.availableQualities
                .map(
                  (e) => ListTile(
                    title: Text('${e.quality}p'),
                    onTap: () {
                      onTap != null ? onTap!() : Navigator.of(context).pop();
                      playerCtr.changeVideoQuality(e.quality);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _VideoPlaybackSelectorMob extends StatelessWidget {
  final void Function()? onTap;
  final String? tag;

  const _VideoPlaybackSelectorMob({
    required this.onTap,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: AllPlayerController.videoPlaybackSpeeds
            .map(
              (e) => ListTile(
                title: Text(e),
                onTap: () {
                  onTap != null ? onTap!() : Navigator.of(context).pop();
                  playerCtr.setVideoPlayback(e);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MobileOverlayBottomControllers extends StatelessWidget {
  final String? tag;

  const _MobileOverlayBottomControllers({
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    const durationTextStyle = TextStyle(color: Colors.white70);
    const itemColor = Colors.white;
    final playerCtr = context.read<AllPlayerController>();

    return BlocBuilder<AllPlayerController, AllPlayerState>(
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Row(
                children: [
                  Text(
                    playerCtr.calculateVideoDuration(state.videoPosition),
                    style: const TextStyle(color: itemColor),
                  ),
                  const Text(' / ', style: durationTextStyle),
                  Text(
                    playerCtr.calculateVideoDuration(state.videoDuration),
                    style: durationTextStyle,
                  ),
                ],
              ),
              const Spacer(),
              MaterialIconButton(
                toolTipMesg: state.isFullScreen
                    ? playerCtr.playerLabels.exitFullScreen ??
                        'Exit full screen${kIsWeb ? ' (f)' : ''}'
                    : playerCtr.playerLabels.fullscreen ??
                        'Fullscreen${kIsWeb ? ' (f)' : ''}',
                color: itemColor,
                onPressed: () {
                  if (state.isOverlayVisible) {
                    if (state.isFullScreen) {
                      playerCtr.disableFullScreen(context);
                    } else {
                      playerCtr.enableFullScreen(context);
                    }
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
          ),
          if (state.isFullScreen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: Visibility(
                visible: state.isOverlayVisible,
                child: AllProgressBar(
                  controller: playerCtr,
                  alignment: Alignment.topCenter,
                  progressBarConfig: playerCtr.progressBarConfig,
                ),
              ),
            )
          else
            AllProgressBar(
              controller: playerCtr,
              alignment: Alignment.bottomCenter,
              progressBarConfig: playerCtr.progressBarConfig,
            ),
        ],
      ),
    );
  }
}
