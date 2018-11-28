import 'dart:async';

import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/material_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final Future<dynamic> Function() onExpandCollapse;
  final bool fullScreen;
  final ChewieProgressColors materialProgressColors;
  final Widget placeholder;
  final double aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final bool isLive;

  PlayerWithControls({
    Key key,
    @required this.controller,
    @required this.onExpandCollapse,
    @required this.aspectRatio,
    this.fullScreen = false,
    this.showControls = true,
    this.materialProgressColors,
    this.placeholder,
    this.autoPlay,
    this.isLive = false,
  }) : super(key: key);

  @override
  State createState() {
    return new _VideoPlayerWithControlsState();
  }
}

class _VideoPlayerWithControlsState extends State<PlayerWithControls> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return _buildPlayerWithControls(controller, context);
  }

  Widget _buildPlayerWithControls(
      VideoPlayerController controller, BuildContext context) {
    VideoPlayer videoPlayer = VideoPlayer(controller);
    var ctx = MediaQuery.of(context);
    if (!controller.value.initialized)
      return widget.placeholder ?? CircularProgressIndicator();
    return Stack(
      children: <Widget>[
        Center(
          child: FittedBox(
            child: Container(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: ctx.orientation == Orientation.landscape
                  ? videoPlayer
                  : Hero(tag: controller, child: videoPlayer),
            ),
          ),
        ),
        _buildControls(context, controller),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    VideoPlayerController controller,
  ) {
    return widget.showControls
        ? new MaterialControls(
            controller: controller,
            onExpandCollapse: widget.onExpandCollapse,
            fullScreen: widget.fullScreen,
            progressColors: widget.materialProgressColors,
            autoPlay: widget.autoPlay,
            isLive: widget.isLive,
          )
        : new Container();
  }

  @override
  void initState() {
    // Hack to show the video when it starts playing. Should be fixed by the
    // Plugin IMO.
    widget.controller.addListener(_onPlay);

    super.initState();
  }

  @override
  void didUpdateWidget(PlayerWithControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller.dataSource != oldWidget.controller.dataSource) {
      widget.controller.addListener(_onPlay);
    }
  }

  @override
  dispose() {
    widget.controller.removeListener(_onPlay);
    super.dispose();
  }

  void _onPlay() {
    if (widget.controller.value.isPlaying) {
      setState(() {
        widget.controller.removeListener(_onPlay);
      });
    }
  }
}
