import 'package:flutter/material.dart';
import 'package:video_partial_cache/video_partial_cache.dart';

/// A seek-bar-like line showing which parts of a video's timeline are cached.
///
/// Colors come from the theme: the track is `colorScheme.surfaceContainerHighest`
/// and the cached parts `colorScheme.primary`, unless overridden.
class CacheTimelineBar extends StatelessWidget {
  const CacheTimelineBar({
    super.key,
    required this.spans,
    this.height = 6,
    this.cachedColor,
    this.trackColor,
  });

  final List<CachedSpan> spans;
  final double height;
  final Color? cachedColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'cached parts',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TimelinePainter(
            spans: spans,
            cached: cachedColor ?? scheme.primary,
            track: trackColor ?? scheme.surfaceContainerHighest,
            // In a right-to-left layout the timeline starts on the right
            // (wrap in Directionality(ltr) to match an LTR player).
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.spans,
    required this.cached,
    required this.track,
    required this.rtl,
  });

  final List<CachedSpan> spans;
  final Color cached;
  final Color track;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final bar = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas
      ..save()
      ..clipRRect(bar)
      ..drawRRect(bar, Paint()..color = track);

    final paint = Paint()..color = cached;
    for (final s in spans) {
      var start = s.start.clamp(0.0, 1.0) * size.width;
      var end = s.end.clamp(0.0, 1.0) * size.width;
      if (rtl) (start, end) = (size.width - end, size.width - start);
      // Keep tiny cached parts visible.
      if (end - start < 1) end = start + 1;
      canvas.drawRect(Rect.fromLTRB(start, 0, end, size.height), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.spans != spans || old.cached != cached || old.track != track || old.rtl != rtl;
}
