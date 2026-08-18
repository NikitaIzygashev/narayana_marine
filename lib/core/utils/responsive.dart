import 'package:flutter/widgets.dart';

bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < 700;
bool isNarrow(BuildContext context) => MediaQuery.sizeOf(context).width < 360;
bool isTablet(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width >= 700 && width < 1100;
}

double pageGutter(BuildContext context) => isNarrow(context)
    ? 16
    : isCompact(context)
    ? 20
    : 48;
