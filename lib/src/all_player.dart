import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as uni_html;

import '../all_player.dart';
import 'widgets/double_tap_icon.dart';
import 'widgets/material_icon_button.dart';

part 'widgets/animated_play_pause_icon.dart';
part 'widgets/core/overlays/mobile_bottomsheet.dart';
part 'widgets/core/overlays/mobile_overlay.dart';
part 'widgets/core/overlays/overlays.dart';
part 'widgets/core/overlays/web_dropdown_menu.dart';
part 'widgets/core/overlays/web_overlay.dart';
part 'widgets/core/all_core_player.dart';
part 'widgets/core/video_gesture_detector.dart';
part 'widgets/full_screen_view.dart';

class AllPlayer extends StatefulWidget {
  final AllPlayerController controller;
  final double frameAspectRatio;
  final double videoAspectRatio;
  final bool alwaysShowProgressBar;
  final bool matchVideoAspectRatioToFrame;
  final bool matchFrameAspectRatioToVideo;
  final AllProgressBarConfig progressBarConfig;
  final AllPlayerLabels playerLabels;
  final Widget Function(OverLayOptions options)? overlayBuilder;
  final Widget Function()? onVideoError;
  final Widget? videoTitle;
  final Color? backgroundColor;
  final DecorationImage? videoThumbnail;
  final Future<void> Function(bool isFullScreen)? onToggleFullScreen;
  final WidgetBuilder? onLoading;

  AllPlayer({
    required this.controller,
    super.key,
    this.frameAspectRatio = 16 / 9,
    this.videoAspectRatio = 16 / 9,
    this.alwaysShowProgressBar = true,
    this.progressBarConfig = const AllProgressBarConfig(),
    this.playerLabels = const AllPlayerLabels(),
    this.overlayBuilder,
    this.videoTitle,
    this.matchVideoAspectRatioToFrame = false,
    this.matchFrameAspectRatioToVideo = false,
    this.onVideoError,
    this.backgroundColor,
    this.videoThumbnail,
    this.onToggleFullScreen,
    this.onLoading,
  }) {
    _applyConfig();
  }

  static bool enableLogs = true;

  void _applyConfig() {
    controller.playerLabels = playerLabels;
    controller.alwaysShowProgressBar = alwaysShowProgressBar;
    controller.progressBarConfig = progressBarConfig;
    controller.overlayBuilder = overlayBuilder;
    controller.videoTitle = videoTitle;
    controller.videoThumbnail = videoThumbnail;
    controller.onToggleFullScreen = onToggleFullScreen;
    controller.onLoading = onLoading;
  }

  @override
  State<AllPlayer> createState() => _AllPlayerState();
}

class _AllPlayerState extends State<AllPlayer> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      uni_html.document.onContextMenu.listen((event) => event.preventDefault());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.controller,
      child: BlocBuilder<AllPlayerController, AllPlayerState>(
        builder: (context, state) {
          if (widget.controller.isIframe) {
            return _buildIframePlayer();
          }

          double frameAspectRatio = widget.frameAspectRatio;
          if (widget.matchFrameAspectRatioToVideo &&
              widget.controller.videoCtr?.value.isInitialized == true) {
            frameAspectRatio = widget.controller.videoCtr!.value.aspectRatio;
          }

          if (state.playerStatus == AllPlayerStatus.error) {
            return widget.onVideoError?.call() ?? _buildErrorWidget(frameAspectRatio);
          }

          final isInitialized =
              widget.controller.videoCtr?.value.isInitialized ?? false;

          return Center(
            child: ColoredBox(
              color: widget.backgroundColor ?? Colors.black,
              child: AspectRatio(
                aspectRatio: frameAspectRatio,
                child: isInitialized
                    ? _buildNativePlayer()
                    : _thumbnailAndLoadingWidget(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIframePlayer() {
    if (widget.controller.youtubeIframeController == null) {
      return Center(child: _buildLoading());
    }
    return Center(
      child: ColoredBox(
        color: widget.backgroundColor ?? Colors.black,
        child: AspectRatio(
          aspectRatio: widget.frameAspectRatio,
          child: YoutubePlayer(
            controller: widget.controller.youtubeIframeController!,
            aspectRatio: widget.videoAspectRatio,
          ),
        ),
      ),
    );
  }

  Widget _buildNativePlayer() {
    final videoAspectRatio = widget.matchVideoAspectRatioToFrame
        ? (widget.controller.videoCtr?.value.aspectRatio ?? widget.videoAspectRatio)
        : widget.videoAspectRatio;

    return _AllCoreVideoPlayer(
      videoPlayerCtr: widget.controller.videoCtr!,
      videoAspectRatio: videoAspectRatio,
    );
  }

  Widget _buildErrorWidget(double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              color: Colors.yellow,
              size: 32,
            ),
            const SizedBox(height: 20),
            Text(
              widget.controller.state.errorMessage ?? widget.playerLabels.error,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return widget.onLoading?.call(context) ??
        const Center(
          child: CircularProgressIndicator(
            backgroundColor: Colors.black87,
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
  }

  Widget _thumbnailAndLoadingWidget() {
    if (widget.videoThumbnail == null) {
      return _buildLoading();
    }

    return SizedBox.expand(
      child: TweenAnimationBuilder<double>(
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: child,
        ),
        tween: Tween<double>(begin: 0.2, end: 0.7),
        duration: const Duration(milliseconds: 400),
        child: DecoratedBox(
          decoration: BoxDecoration(image: widget.videoThumbnail),
          child: Center(
            child: _buildLoading(),
          ),
        ),
      ),
    );
  }
}

typedef AllVideoPlayer = AllPlayer;
