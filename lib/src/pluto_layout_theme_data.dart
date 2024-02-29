import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

@immutable
class PlutoLayoutThemeData with Diagnosticable {

  /// Creates a theme that can be used for [ThemeData.plutoLayoutTheme].
  const PlutoLayoutThemeData({
    this.tabTextStyle,
    this.dividerColor,
    this.tabColor,
    this.tabDisabledColor,
    this.tabBackgroundColor,
  });

  /// Used to configure the [DefaultTextStyle] for the [PlutoLayout.tab] widget.
  final TextStyle? tabTextStyle;

  /// Overrides the default value for [PlutoLayout.dividerColor].
  final Color? dividerColor;

  /// Overrides the default value for [PlutoLayout.tabColor].
  final Color? tabColor;

  /// Overrides the default value for [PlutoLayout.tabDisabledColor].
  final Color? tabDisabledColor;

  /// Overrides the default value for [PlutoLayout.tabBackgroundColor].
  final Color? tabBackgroundColor;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  PlutoLayoutThemeData copyWith({
    TextStyle? tabTextStyle,
    Color? dividerColor,
    Color? tabColor,
    Color? tabDisabledColor,
    Color? tabBackgroundColor,
  }) {
    return PlutoLayoutThemeData(
      tabTextStyle: tabTextStyle ?? this.tabTextStyle,
      dividerColor: dividerColor ?? this.dividerColor,
      tabColor: tabColor ?? this.tabColor,
      tabDisabledColor: tabDisabledColor ?? this.tabDisabledColor,
      tabBackgroundColor: tabBackgroundColor ?? this.tabBackgroundColor,
    );
  }

  /// Linearly interpolate between two Pluto Layout Themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static PlutoLayoutThemeData lerp(PlutoLayoutThemeData? a, PlutoLayoutThemeData? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return PlutoLayoutThemeData(
      tabTextStyle: TextStyle.lerp(a?.tabTextStyle, b?.tabTextStyle, t),
      dividerColor: Color.lerp(a?.dividerColor, b?.dividerColor, t),
      tabColor: Color.lerp(a?.tabColor, b?.tabColor, t),
      tabDisabledColor: Color.lerp(a?.tabDisabledColor, b?.tabDisabledColor, t),
      tabBackgroundColor: Color.lerp(a?.tabBackgroundColor, b?.tabBackgroundColor, t),
    );
  }

  @override
  int get hashCode => Object.hash(
      tabTextStyle,
      dividerColor,
      tabColor,
      tabDisabledColor,
      tabBackgroundColor,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PlutoLayoutThemeData
        && other.tabTextStyle == tabTextStyle
        && other.tabColor == tabColor
        && other.tabDisabledColor == tabDisabledColor
        && other.tabBackgroundColor == tabBackgroundColor
        && other.dividerColor == dividerColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextStyle>('tabTextStyle', tabTextStyle, defaultValue: null));
    properties.add(ColorProperty('dividerColor', dividerColor, defaultValue: null));
    properties.add(ColorProperty('tabColor', tabColor, defaultValue: null));
    properties.add(ColorProperty('tabDisabledColor', tabDisabledColor, defaultValue: null));
    properties.add(ColorProperty('tabBackgroundColor', tabBackgroundColor, defaultValue: null));
  }
}