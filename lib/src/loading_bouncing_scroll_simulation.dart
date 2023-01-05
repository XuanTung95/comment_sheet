import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingConfig {
  double triggerLoadingDistance;
  double loadingHeight;
  Future Function() loading;

  bool enable = true;

  LoadingConfig({
    required this.triggerLoadingDistance,
    required this.loadingHeight,
    required this.loading,
  });
}

class LoadingBouncingScrollSimulation extends BouncingScrollSimulation {
  LoadingBouncingScrollSimulation({
    required double position,
    required double velocity,
    required double leadingExtent,
    required double trailingExtent,
    required SpringDescription spring,
    Tolerance tolerance = Tolerance.defaultTolerance,
    required this.loadingConfig,
  }) : super(
      position: position,
      velocity: velocity,
      leadingExtent: leadingExtent,
      trailingExtent: trailingExtent,
      spring: spring,
      tolerance: tolerance);

  final LoadingConfig loadingConfig;
  bool _isDelaying = false;

  double _delayStartTime = double.infinity;
  double _delayDuration = 0;

  double get _delayAt => -loadingConfig.loadingHeight;

  @override
  double x(double time) {
    if (!loadingConfig.enable) {
      return super.x(time);
    }
    final x = super.x(time);
    if (x > _delayAt) {
      if (!_isDelaying && time < _delayStartTime) {
        _delayStartTime = time;
        _isDelaying = true;
        final start = DateTime.now().millisecondsSinceEpoch;
        loadingConfig.loading.call().then((value) {
          _delayDuration =
              (DateTime.now().millisecondsSinceEpoch - start) / 1000;
          _isDelaying = false;
        }).onError((error, stackTrace) {
          _delayDuration =
              (DateTime.now().millisecondsSinceEpoch - start) / 1000;
          _isDelaying = false;
        });
      }
    } else {
      _delayStartTime = double.infinity;
    }
    if (time >= _delayStartTime) {
      if (_isDelaying) {
        return _delayAt;
      } else {
        return super.x(time - _delayDuration);
      }
    }
    return super.x(time);
  }

  /// The velocity of the object in the simulation at the given time.
  @override
  double dx(double time) {
    if (!loadingConfig.enable) {
      return super.dx(time);
    }
    if (time >= _delayStartTime) {
      if (_isDelaying) {
        return super.dx(_delayStartTime);
      } else {
        return super.dx(time - _delayDuration);
      }
    }
    return super.dx(time);
  }

  /// Whether the simulation is "done" at the given time.
  @override
  bool isDone(double time) {
    if (!loadingConfig.enable) {
      return super.isDone(time);
    }
    if (time >= _delayStartTime) {
      if (_isDelaying) {
        return super.isDone(_delayStartTime);
      } else {
        return super.isDone(time - _delayDuration);
      }
    }
    return super.isDone(time);
  }
}
