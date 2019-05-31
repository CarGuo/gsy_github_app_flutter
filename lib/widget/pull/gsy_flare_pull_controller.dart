import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controller.dart';

mixin GSYFlarePullController implements FlareController {
  ActorAnimation _pullAnimation;

  double pulledExtentFlare = 0;
  double _refreshTriggerPullDistance = 140;

  @override
  void initialize(FlutterActorArtboard artboard) {
    _pullAnimation = artboard.getAnimation("Earth Moving");
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if(getPlayAuto) {
      return false;
    }
    double animationPosition = pulledExtentFlare / _refreshTriggerPullDistance;
    animationPosition *= animationPosition;
    _pullAnimation.apply(
        _pullAnimation.duration * animationPosition, artboard, 1.0);
    return true;
  }

  bool get getPlayAuto;

}
