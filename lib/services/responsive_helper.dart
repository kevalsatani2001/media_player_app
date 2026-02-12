import 'package:flutter/cupertino.dart';

class R {
  static double w(BuildContext c, double v) => MediaQuery.of(c).size.width * (v / 375);
  static double h(BuildContext c, double v) => MediaQuery.of(c).size.height * (v / 812);
  static double sp(BuildContext c, double v) => (MediaQuery.of(c).size.width / 375) * v;
}