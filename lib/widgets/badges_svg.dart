// badges_svg.dart, badge count logic and svg details

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart';

class BadgesSVG {
  static Widget getBadge(int count) {
    String assetPath;

    if (count == 0) {
      assetPath = "assets/badges/badge_0.svg"; // grey
    } else if (count >= 20) {
      assetPath = "assets/badges/badge_5.svg"; // red
    } else if (count >= 15) {
      assetPath = "assets/badges/badge_4.svg"; // purple
    } else if (count >= 10) {
      assetPath = "assets/badges/badge_3.svg"; // blue
    } else if (count >= 5) {
      assetPath = "assets/badges/badge_2.svg"; // green
    } else {
      assetPath = "assets/badges/badge_1.svg"; // yellow
    }

    return SvgPicture.asset(
      assetPath,
      width: 30,
      height: 30,
      semanticsLabel: "Badge",
    );
  }
}

Widget buildBadge(int count) {
  return BadgesSVG.getBadge(count);
}
