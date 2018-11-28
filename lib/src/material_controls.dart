import 'dart:async';

import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/material_progress_bar.dart';
import 'package:chewie/src/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaterialControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool fullScreen;
  final Future<dynamic> Function() onExpandCollapse;
  final ChewieProgressColors progressColors;
  final bool autoPlay;
  final bool isLive;
  final iconSize = 20.0;
  final barHeight = 30.0;
  final buttonPadding = 24.0;
  Color backgroundColor = new Color.fromRGBO(41, 41, 41, 0.7);
  final iconColor = Colors.white;

  MaterialControls({
    @required this.controller,
    @required this.fullScreen,
    @required this.onExpandCollapse,
    @required this.progressColors,
    @required this.autoPlay,
    @required this.isLive,
  });

  @override
  State<StatefulWidget> createState() {
    return new _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _showTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  final marginSize = 5.0;

  @override
  Widget build(BuildContext context) {
    return _latestValue != null &&
                !_latestValue.isPlaying &&
                _latestValue.duration == null ||
            _latestValue.isBuffering
        ? Container()
        : Column(
            children: <Widget>[
              _buildTopBar(widget.controller),
              _buildHitArea(),
              _buildBottomBar(context, widget.controller),
            ],
          );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    widget.controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void initState() {
    _initialize();

    super.initState();
  }

  @override
  void didUpdateWidget(MaterialControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.dataSource != oldWidget.controller.dataSource) {
      _dispose();
      _initialize();
    }
  }

  Widget _buildTopBar(
    VideoPlayerController controller,
  ) {
    return new Container(
      height: widget.barHeight,
      margin: new EdgeInsets.only(
        top: 25.0,
        right: marginSize,
        left: marginSize,
      ),
      child: new Row(
        children: <Widget>[
          _buildBackButton(),
          Expanded(child: new Container()),
          _buildMuteButton(controller),
        ],
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
    VideoPlayerController controller,
  ) {
    return new AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: new Duration(milliseconds: 300),
      child: new Container(
        height: widget.barHeight,
        color: widget.backgroundColor,
        child: new Row(
          children: <Widget>[
            _buildPlayPause(controller),
            widget.isLive ? const SizedBox() : _buildProgressBar(),
            widget.isLive
                ? Expanded(child: const Text('LIVE'))
                : _buildPosition(),
            _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return new GestureDetector(
      onTap: _onExpandCollapse,
      child: new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new Container(
          height: widget.barHeight,
          margin: new EdgeInsets.only(right: 12.0),
          padding: new EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: new Center(
            child: new Icon(
              widget.fullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: widget.iconColor,
              size: widget.iconSize + 10,
            ),
          ),
        ),
      ),
    );
  }

  Offset start;
  Offset end;

  bool horizontalDragging() {
    if (start == null || end == null) return false;
    return (end.dx.toInt() - start.dx.toInt()).abs() >
        (end.dy.toInt() - start.dy.toInt()).abs();
  }

  bool verticalDragging() {
    if (start == null || end == null) return false;
    return (end.dx.toInt() - start.dx.toInt()).abs() <
        (end.dy.toInt() - start.dy.toInt()).abs();
  }

  bool horizontalForward() {
    return end.dx.toInt() - start.dx.toInt() > 0;
  }

  Duration calculatePosition() {
    var val = widget.controller.value;
    int offset = end.dx.toInt() - start.dx.toInt();
    int position = val.position.inSeconds + offset;
    return Duration(
        seconds: position = position < 0
            ? 0
            : (position > val.duration.inSeconds
                ? val.duration.inSeconds - 1
                : position));
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: new GestureDetector(
        onTap: _latestValue != null && _latestValue.isPlaying
            ? _cancelAndRestartTimer
            : () {
                _hideTimer?.cancel();

                setState(() {
                  _hideStuff = false;
                });
              },
        onHorizontalDragStart: (details) {
          if (!widget.controller.value.initialized) {
            return;
          }
        },
        onHorizontalDragEnd: (detail) {
          if (!widget.controller.value.initialized) {
            return;
          }
          if (horizontalDragging()) {
            Duration position = calculatePosition();
            widget.controller.seekTo(position);
          }
          start = null;
          end = null;
          if (!widget.controller.value.isPlaying) {
            widget.controller.play();
          }
        },
        onHorizontalDragUpdate: (detail) {
          if (!widget.controller.value.initialized) {
            return;
          }

          if (start == null) start = detail.globalPosition;
          end = detail.globalPosition;
          if (horizontalDragging()) {
            if (widget.controller.value.isPlaying) {
              widget.controller.pause();
            }
            setState(() {});
          }
        },
        child: new Container(
          color: Colors.transparent,
          child: Center(
            child: horizontalDragging()
                ? Opacity(
                    opacity: 0.5,
                    child: Container(
                      alignment: AlignmentDirectional.center,
                      width: 70.0,
                      height: 70.0,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            horizontalForward() ? Icons.fast_forward : Icons.fast_rewind,
                            color: widget.iconColor,
                            size: 40.0,
                          ),
                          Expanded(
                            child: Text(
                              "${formatDuration(calculatePosition())}",
                              style: TextStyle(color: widget.iconColor),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildBackButton() {
    return new GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();
        if (widget.fullScreen)
          widget.onExpandCollapse();
        else
          Navigator.of(context, rootNavigator: true).pop(context);
      },
      child: new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new Container(
          decoration: new BoxDecoration(
            color: widget.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: new Container(
            height: widget.barHeight,
            padding: new EdgeInsets.only(
              left: widget.buttonPadding,
              right: widget.buttonPadding,
            ),
            child: new Icon(
              Icons.chevron_left,
              color: widget.iconColor,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return new GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new Container(
          decoration: new BoxDecoration(
            color: widget.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: new Container(
            height: widget.barHeight,
            padding: new EdgeInsets.only(
                left: widget.buttonPadding, right: widget.buttonPadding),
            child: new Icon(
              (_latestValue != null && _latestValue.volume > 0)
                  ? Icons.volume_up
                  : Icons.volume_off,
              color: widget.iconColor,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return new GestureDetector(
      onTap: _playPause,
      child: new Container(
        height: widget.barHeight,
        color: Colors.transparent,
        margin: new EdgeInsets.only(left: 8.0, right: 4.0),
        padding: new EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: new Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: widget.iconColor,
          size: widget.iconSize + 10,
        ),
      ),
    );
  }

  Widget _buildPosition() {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return new Padding(
      padding: new EdgeInsets.only(right: 10.0),
      child: new Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: new TextStyle(fontSize: 14.0, color: widget.iconColor),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
    });
  }

  Future<Null> _initialize() async {
    widget.controller.addListener(_updateState);

    _updateState();

    if ((widget.controller.value != null &&
            widget.controller.value.isPlaying) ||
        widget.autoPlay) {
      _startHideTimer();
    }

    _showTimer = new Timer(new Duration(milliseconds: 200), () {
      setState(() {
        _hideStuff = false;
      });
    });
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      widget.onExpandCollapse().then((dynamic _) {
        _showAfterExpandCollapseTimer =
            new Timer(new Duration(milliseconds: 300), () {
          setState(() {
            _cancelAndRestartTimer();
          });
        });
      });
    });
  }

  void _playPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        widget.controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!widget.controller.value.initialized) {
          widget.controller.initialize().then((_) {
            widget.controller.play();
          });
        } else {
          widget.controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = new Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = widget.controller.value;
    });
  }

  Widget _buildProgressBar() {
    return new Expanded(
      child: new Padding(
        padding: new EdgeInsets.only(right: 20.0),
        child: new MaterialVideoProgressBar(
          widget.controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: widget.progressColors ??
              ChewieProgressColors(
                playedColor: new Color.fromARGB(120, 255, 255, 255),
                handleColor: new Color.fromARGB(255, 255, 255, 255),
                bufferedColor: new Color.fromARGB(60, 255, 255, 255),
                backgroundColor: new Color.fromARGB(20, 255, 255, 255),
              ),
        ),
      ),
    );
  }
}
