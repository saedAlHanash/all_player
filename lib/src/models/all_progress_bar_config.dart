import 'package:flutter/material.dart';

typedef GetProgressBarBackgroundPaint = Paint Function({
  double? width,
  double? height,
  double? circleHandlerRadius,
});

typedef GetProgressBarPlayedPaint = Paint Function({
  double? width,
  double? height,
  double? playedPart,
  double? circleHandlerRadius,
});

typedef GetProgressBarBufferedPaint = Paint Function({
  double? width,
  double? height,
  double? playedPart,
  double? circleHandlerRadius,
  double? bufferedStart,
  double? bufferedEnd,
});

typedef GetProgressBarHandlePaint = Paint Function({
  double? width,
  double? height,
  double? playedPart,
  double? circleHandlerRadius,
});

class AllProgressBarConfig {
  const AllProgressBarConfig({
    this.playingBarColor = Colors.red,
    this.bufferedBarColor = const Color.fromRGBO(255, 255, 255, 0.38),
    this.circleHandlerColor = Colors.red,
    this.alwaysVisibleCircleHandler = false,
    this.backgroundColor = const Color.fromRGBO(255, 255, 255, 0.24),
    this.getPlayedPaint,
    this.getBufferedPaint,
    this.getCircleHandlerPaint,
    this.getBackgroundPaint,
    this.height = 3.6,
    this.padding = EdgeInsets.zero,
    this.circleHandlerRadius = 8,
    this.curveRadius = 4,
  });

  final Color playingBarColor;
  final Color bufferedBarColor;
  final Color circleHandlerColor;
  final bool alwaysVisibleCircleHandler;
  final Color backgroundColor;
  final GetProgressBarPlayedPaint? getPlayedPaint;
  final GetProgressBarBufferedPaint? getBufferedPaint;
  final GetProgressBarHandlePaint? getCircleHandlerPaint;
  final GetProgressBarBackgroundPaint? getBackgroundPaint;
  final double height;
  final EdgeInsetsGeometry padding;
  final double circleHandlerRadius;
  final double curveRadius;

  AllProgressBarConfig copyWith({
    Color? playingBarColor,
    Color? bufferedBarColor,
    Color? circleHandlerColor,
    bool? alwaysVisibleCircleHandler,
    Color? backgroundColor,
    GetProgressBarPlayedPaint? getPlayedPaint,
    GetProgressBarBufferedPaint? getBufferedPaint,
    GetProgressBarHandlePaint? getCircleHandlerPaint,
    GetProgressBarBackgroundPaint? getBackgroundPaint,
    double? height,
    EdgeInsetsGeometry? padding,
    double? circleHandlerRadius,
    double? curveRadius,
  }) {
    return AllProgressBarConfig(
      playingBarColor: playingBarColor ?? this.playingBarColor,
      bufferedBarColor: bufferedBarColor ?? this.bufferedBarColor,
      circleHandlerColor: circleHandlerColor ?? this.circleHandlerColor,
      alwaysVisibleCircleHandler:
          alwaysVisibleCircleHandler ?? this.alwaysVisibleCircleHandler,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      getPlayedPaint: getPlayedPaint ?? this.getPlayedPaint,
      getBufferedPaint: getBufferedPaint ?? this.getBufferedPaint,
      getCircleHandlerPaint: getCircleHandlerPaint ?? this.getCircleHandlerPaint,
      getBackgroundPaint: getBackgroundPaint ?? this.getBackgroundPaint,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      circleHandlerRadius: circleHandlerRadius ?? this.circleHandlerRadius,
      curveRadius: curveRadius ?? this.curveRadius,
    );
  }
}
