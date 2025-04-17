import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart';

class BadgesSVG {
  static Widget getBadge(int count) {
    String assetPath;

    if (count >= 20) {
      assetPath = "assets/badges/badge_5.svg";
    } else if (count >= 15) {
      assetPath = "assets/badges/badge_4.svg";
    } else if (count >= 10) {
      assetPath = "assets/badges/badge_3.svg";
    } else if (count >= 5) {
      assetPath = "assets/badges/badge_2.svg";
    } else {
      assetPath = "assets/badges/badge_1.svg";
    }

    return SvgPicture.asset(
      assetPath,
      width: 30,
      height: 30,
      semanticsLabel: "Badge",
    );
  }
}
