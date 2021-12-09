import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controller.dart';

mixin GSYFlarePullMutliController implements FlareController {
  late ActorAnimation? _loadingAnimation;
  late ActorAnimation? _successAnimation;
  late ActorAnimation? _pullAnimation;
  late ActorAnimation? _cometAnimation;

  double pulledExtentFlare = 0;
  bool _isSurround = false;

  double _refreshTriggerPullDistance = 140;

  double _successTime = 0.0;
  double _loadingTime = 0.0;
  double _cometTime = 0.0;

  @override
  void initialize(FlutterActorArtboard artboard) {
    _pullAnimation = artboard.getAnimation("pull");
    _successAnimation = artboard.getAnimation("success");
    _loadingAnimation = artboard.getAnimation("loading");
    _cometAnimation = artboard.getAnimation("idle comet");
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    double animationPosition = pulledExtentFlare / _refreshTriggerPullDistance;
    animationPosition *= animationPosition;
    _cometTime += elapsed;
    _cometAnimation?.apply(_cometTime % _cometAnimation!.duration, artboard, 1.0);
    _pullAnimation?.apply(
        _pullAnimation!.duration * animationPosition, artboard, 1.0);
    if (_isSurround) {
      _successTime += elapsed;
      if (_successTime >= _successAnimation!.duration) {
        _loadingTime += elapsed;
      }
    } else {
      _successTime = _loadingTime = 0.0;
    }
    if (_successTime >= _successAnimation!.duration) {
      _loadingAnimation?.apply(
          _loadingTime % _loadingAnimation!.duration, artboard, 1.0);
    } else if (_successTime > 0.0) {
      _successAnimation?.apply(_successTime, artboard, 1.0);
    }
    return true;
  }

  void onRefreshing() {
    _isSurround = true;
  }

  void onRefreshEnd() {
    _isSurround = false;
  }

  bool get getPlayAuto;
}
