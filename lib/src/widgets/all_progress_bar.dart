import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../controllers/all_player_controller.dart';
import '../controllers/all_player_state.dart';
import '../models/all_progress_bar_config.dart';

/// Renders progress bar for the video using custom paint.
class AllProgressBar extends StatefulWidget {
  const AllProgressBar({
    this.tag,
    this.controller,
    super.key,
    this.progressBarConfig = const AllProgressBarConfig(),
    this.onDragStart,
    this.onDragEnd,
    this.onDragUpdate,
    this.alignment = Alignment.center,
  });

  final AllProgressBarConfig progressBarConfig;
  final void Function()? onDragStart;
  final void Function()? onDragEnd;
  final void Function()? onDragUpdate;
  final Alignment alignment;
  final String? tag;
  final AllPlayerController? controller;

  @override
  State<AllProgressBar> createState() => _AllProgressBarState();
}

class _AllProgressBarState extends State<AllProgressBar> {
  AllPlayerController get _controller =>
      widget.controller ?? context.read<AllPlayerController>();
  bool _controllerWasPlaying = false;

  void seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = (tapPos.dx / box.size.width).clamp(0.0, 1.0);
      final Duration total = _controller.totalVideoLength;
      final Duration position = total * relative;
      _controller.seekTo(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllPlayerController, AllPlayerState>(
      bloc: widget.controller,
      builder: (context, state) {
        final videoPlayerValue = _controller.videoPlayerValue;
        if (videoPlayerValue == null) return const SizedBox();

        return LayoutBuilder(
          builder: (context, size) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: _progressBar(size, state, videoPlayerValue),
              onHorizontalDragStart: (DragStartDetails details) {
                if (!videoPlayerValue.isInitialized) return;
                _controllerWasPlaying = _controller.isVideoPlaying;
                if (_controllerWasPlaying) {
                  _controller.pause();
                }
                widget.onDragStart?.call();
              },
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                if (!videoPlayerValue.isInitialized) return;
                _controller.isShowOverlay(true);
                seekToRelativePosition(details.globalPosition);
                widget.onDragUpdate?.call();
              },
              onHorizontalDragEnd: (DragEndDetails details) {
                if (_controllerWasPlaying) {
                  _controller.play();
                }
                _controller.toggleVideoOverlay();
                widget.onDragEnd?.call();
              },
              onTapDown: (TapDownDetails details) {
                if (!videoPlayerValue.isInitialized) return;
                seekToRelativePosition(details.globalPosition);
              },
            );
          },
        );
      },
    );
  }

  Widget _progressBar(
    BoxConstraints size,
    AllPlayerState state,
    VideoPlayerValue videoPlayerValue,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: widget.progressBarConfig.padding,
        child: SizedBox(
          width: size.maxWidth,
          height: widget.progressBarConfig.circleHandlerRadius * 2,
          child: Align(
            alignment: widget.alignment,
            child: CustomPaint(
              painter: _ProgressBarPainter(
                videoPlayerValue,
                progressBarConfig: widget.progressBarConfig.copyWith(
                  circleHandlerRadius: state.isOverlayVisible ||
                          widget.progressBarConfig.alwaysVisibleCircleHandler
                      ? widget.progressBarConfig.circleHandlerRadius
                      : 0,
                ),
              ),
              size: Size(
                double.maxFinite,
                widget.progressBarConfig.height,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, {this.progressBarConfig});

  final VideoPlayerValue value;
  final AllProgressBarConfig? progressBarConfig;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final double height = progressBarConfig!.height;
    final double width = size.width;
    final double curveRadius = progressBarConfig!.curveRadius;
    final double circleHandlerRadius = progressBarConfig!.circleHandlerRadius;
    final Paint backgroundPaint = progressBarConfig!.getBackgroundPaint != null
        ? progressBarConfig!.getBackgroundPaint!(
            width: width,
            height: height,
            circleHandlerRadius: circleHandlerRadius,
          )
        : (Paint()..color = progressBarConfig!.backgroundColor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset.zero,
          Offset(width, height),
        ),
        Radius.circular(curveRadius),
      ),
      backgroundPaint,
    );
    if (!value.isInitialized) {
      return;
    }

    final double playedPartPercent = value.duration.inMilliseconds > 0
        ? value.position.inMilliseconds / value.duration.inMilliseconds
        : 0;
    final double playedPart =
        playedPartPercent > 1 ? width : playedPartPercent * width;

    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * width;
      final double end = range.endFraction(value.duration) * width;

      final Paint bufferedPaint = progressBarConfig!.getBufferedPaint != null
          ? progressBarConfig!.getBufferedPaint!(
              width: width,
              height: height,
              playedPart: playedPart,
              circleHandlerRadius: circleHandlerRadius,
              bufferedStart: start,
              bufferedEnd: end,
            )
          : (Paint()..color = progressBarConfig!.bufferedBarColor);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, 0),
            Offset(end, height),
          ),
          Radius.circular(curveRadius),
        ),
        bufferedPaint,
      );
    }

    final Paint playedPaint = progressBarConfig!.getPlayedPaint != null
        ? progressBarConfig!.getPlayedPaint!(
            width: width,
            height: height,
            playedPart: playedPart,
            circleHandlerRadius: circleHandlerRadius,
          )
        : (Paint()..color = progressBarConfig!.playingBarColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset.zero,
          Offset(playedPart, height),
        ),
        Radius.circular(curveRadius),
      ),
      playedPaint,
    );

    if (circleHandlerRadius > 0) {
      final Paint handlePaint = progressBarConfig!.getCircleHandlerPaint != null
          ? progressBarConfig!.getCircleHandlerPaint!(
              width: width,
              height: height,
              playedPart: playedPart,
              circleHandlerRadius: circleHandlerRadius,
            )
          : (Paint()..color = progressBarConfig!.circleHandlerColor);

      canvas.drawCircle(
        Offset(playedPart, height / 2),
        circleHandlerRadius,
        handlePaint,
      );
    }
  }
}
