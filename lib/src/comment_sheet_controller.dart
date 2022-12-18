

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';

import '../comment_sheet.dart';

class CommentSheetController {
  double get top => _state?.fakeTop ?? 0;

  CommentSheetState? _state;

  set state(CommentSheetState? value) {
    _state = value;
  }

  VelocityTracker? get velocityTracker => _state?.velocityTracker;

  TickerFuture? animateToPosition(double target) {
    return _state?.animateToPosition(target);
  }
}