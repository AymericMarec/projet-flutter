import 'package:flutter/material.dart';

extension IntToColorX on int {
  Color toColor() => Color(this);
}

extension NullableIntToColorX on int? {
  Color? toColorOrNull() => this == null ? null : Color(this!);
}

