import 'package:flutter/material.dart';

import '../../chewie.dart';

class OptionItem {
  OptionItem({
    required this.onTap,
    required this.iconData,
    required this.title,
    this.subtitle,
    this.controlType,
    required this.iconImage
  });

  final void Function(BuildContext context) onTap;
  final IconData iconData;
  final String title;
  final String? subtitle;
  final String iconImage;
  ControlType? controlType;

  OptionItem copyWith({
    Function(BuildContext context)? onTap,
    IconData? iconData,
    String? title,
    String? subtitle,
    String? iconImage,
    ControlType? controlType,
  }) {
    return OptionItem(
      onTap: onTap ?? this.onTap,
      iconData: iconData ?? this.iconData,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconImage: iconImage ?? this.iconImage,
      controlType: controlType ?? this.controlType,
    );
  }

  @override
  String toString() =>
      'OptionItem(onTap: $onTap, iconData: $iconData, title: $title, subtitle: $subtitle, iconImage : $iconImage, controlType: $controlType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OptionItem &&
        other.onTap == onTap &&
        other.iconData == iconData &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.iconImage == iconImage &&
        other.controlType == controlType ;
  }

  @override
  int get hashCode =>
      onTap.hashCode ^ iconData.hashCode ^ title.hashCode ^ subtitle.hashCode ^  iconImage.hashCode ^ controlType.hashCode;
}
