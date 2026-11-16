import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controllers/all_player_controller.dart';
import '../controllers/all_player_state.dart';
import 'doubble_tap_effect.dart';

class DoubleTapIcon extends StatefulWidget {
  final void Function() onDoubleTap;
  final String? tag;
  final bool iconOnly;
  final bool isForward;
  final double height;
  final double? width;

  const DoubleTapIcon({
    required this.onDoubleTap,
    required this.isForward,
    this.tag,
    super.key,
    this.iconOnly = false,
    this.height = 50,
    this.width,
  });

  @override
  State<DoubleTapIcon> createState() => _DoubleTapIconState();
}

class _DoubleTapIconState extends State<DoubleTapIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> opacityCtr;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    opacityCtr = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    widget.onDoubleTap();
    _animationController.forward().then((_) {
      if (mounted) _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.iconOnly) return iconWithText();
    return DoubleTapRippleEffect(
      onDoubleTap: _onDoubleTap,
      rippleColor: Colors.white,
      wrapper: (parentWidget, curveRadius) {
        final forwardRadius =
            !widget.isForward ? Radius.zero : Radius.circular(curveRadius);
        final backwardRadius =
            widget.isForward ? Radius.zero : Radius.circular(curveRadius);
        return ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: forwardRadius,
            topLeft: forwardRadius,
            bottomRight: backwardRadius,
            topRight: backwardRadius,
          ),
          child: parentWidget,
        );
      },
      child: iconWithText(),
    );
  }

  Widget iconWithText() {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          const icon = Icon(
            Icons.play_arrow_sharp,
            size: 32,
            color: Colors.white,
          );
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: widget.isForward ? 0 : 2,
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: opacityCtr.value,
                        child: icon,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: opacityCtr.value,
                          child: icon,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: opacityCtr.value,
                          child: icon,
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<AllPlayerController, AllPlayerState>(
                  buildWhen: (prev, curr) =>
                      prev.isLeftDbTapIconVisible != curr.isLeftDbTapIconVisible ||
                      prev.isRightDbTapIconVisible != curr.isRightDbTapIconVisible ||
                      prev.leftDoubleTapDuration != curr.leftDoubleTapDuration ||
                      prev.rightDoubleTapDuration != curr.rightDoubleTapDuration,
                  builder: (context, state) {
                    final isVisible = widget.isForward
                        ? state.isRightDbTapIconVisible
                        : state.isLeftDbTapIconVisible;
                    final duration = widget.isForward
                        ? state.rightDoubleTapDuration
                        : state.leftDoubleTapDuration;

                    if (isVisible && duration > 0) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: opacityCtr.value,
                        child: Text(
                          '$duration Sec',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
