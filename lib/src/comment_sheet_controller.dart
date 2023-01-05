import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../comment_sheet.dart';

class CommentSheetController {
  double get top => _state?.fakeTop ?? 0;

  CommentSheetState? _state;

  set state(CommentSheetState? value) {
    _state = value;
  }

  VelocityTracker? get velocityTracker => _state?.velocityTracker;

  BoxConstraints? get size => _state?.size;

  TickerFuture? animateToPosition(double target) {
    return _state?.animateToPosition(target);
  }
}