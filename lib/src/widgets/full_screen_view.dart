part of 'package:all_player/src/all_player.dart';

class FullScreenView extends StatefulWidget {
  final AllPlayerController controller;
  final String? tag;

  const FullScreenView({
    required this.controller,
    this.tag,
    super.key,
  });

  @override
  State<FullScreenView> createState() => _FullScreenViewState();
}

class _FullScreenViewState extends State<FullScreenView> {
  @override
  Widget build(BuildContext context) {
    final playerCtr = widget.controller;
    final loadingWidget = playerCtr.onLoading?.call(context) ??
        const Center(
          child: CircularProgressIndicator(
            backgroundColor: Colors.black87,
            color: Colors.white,
            strokeWidth: 2,
          ),
        );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await playerCtr.disableFullScreen(context, enablePop: false);
        }
      },
      child: BlocProvider.value(
        value: playerCtr,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: BlocBuilder<AllPlayerController, AllPlayerState>(
            builder: (context, state) {
              return Center(
                child: ColoredBox(
                  color: Colors.black,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: playerCtr.videoCtr == null
                          ? loadingWidget
                          : playerCtr.videoCtr!.value.isInitialized
                              ? _AllCoreVideoPlayer(
                                  tag: widget.tag,
                                  videoPlayerCtr: playerCtr.videoCtr!,
                                  videoAspectRatio:
                                      playerCtr.videoCtr?.value.aspectRatio ?? 16 / 9,
                                )
                              : loadingWidget,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
