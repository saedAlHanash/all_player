part of 'package:all_player/src/all_player.dart';

class _AnimatedPlayPauseIcon extends StatefulWidget {
  final double? size;
  final String? tag;

  const _AnimatedPlayPauseIcon({
    this.tag,
    this.size,
  });

  @override
  State<_AnimatedPlayPauseIcon> createState() => _AnimatedPlayPauseIconState();
}

class _AnimatedPlayPauseIconState extends State<_AnimatedPlayPauseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _payCtr;

  @override
  void initState() {
    super.initState();
    _payCtr = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<AllPlayerController>();
    if (controller.isVideoPlaying) {
      _payCtr.forward();
    } else {
      _payCtr.reverse();
    }
  }

  @override
  void dispose() {
    _payCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    return BlocConsumer<AllPlayerController, AllPlayerState>(
      listenWhen: (prev, curr) => prev.playerStatus != curr.playerStatus,
      listener: (context, state) {
        if (state.playerStatus == AllPlayerStatus.playing) {
          _payCtr.forward();
        } else if (state.playerStatus == AllPlayerStatus.paused) {
          _payCtr.reverse();
        }
      },
      builder: (context, state) {
        final isPlaying = playerCtr.isVideoPlaying;
        final tooltipMsg = isPlaying
            ? playerCtr.playerLabels.pause ?? 'Pause${kIsWeb ? ' (space)' : ''}'
            : playerCtr.playerLabels.play ?? 'Play${kIsWeb ? ' (space)' : ''}';

        return MaterialIconButton(
          toolTipMesg: tooltipMsg,
          onPressed: state.isOverlayVisible ? playerCtr.togglePlayPause : null,
          child: onStateChange(state, playerCtr),
        );
      },
    );
  }

  Widget onStateChange(AllPlayerState state, AllPlayerController playerCtr) {
    if (kIsWeb) return _playPause();
    if (state.playerStatus == AllPlayerStatus.loading) {
      return const SizedBox();
    } else {
      return _playPause();
    }
  }

  Widget _playPause() {
    return AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      progress: _payCtr,
      color: Colors.white,
      size: widget.size,
    );
  }
}
