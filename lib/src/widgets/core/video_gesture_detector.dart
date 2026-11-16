part of 'package:all_player/src/all_player.dart';

class _VideoGestureDetector extends StatelessWidget {
  final Widget? child;
  final void Function()? onDoubleTap;
  final void Function()? onTap;
  final String? tag;

  const _VideoGestureDetector({
    this.tag,
    this.child,
    this.onDoubleTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    return MouseRegion(
      onHover: (event) => playerCtr.onOverlayHover(),
      onExit: (event) => playerCtr.onOverlayHoverExit(),
      child: GestureDetector(
        onTap: onTap ?? playerCtr.toggleVideoOverlay,
        onDoubleTap: onDoubleTap,
        child: child,
      ),
    );
  }
}
