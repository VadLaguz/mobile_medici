import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:mobile_medici/shared_ui.dart';

class ThemeButton extends StatelessWidget {
  IconData _getIcon(BuildContext context) {
    var themeMode = EasyDynamicTheme.of(context).themeMode;
    return themeMode == ThemeMode.system
        ? Icons.brightness_auto
        : themeMode == ThemeMode.light
            ? Icons.brightness_high
            : Icons.brightness_4;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: Key('EasyDynamicThemeBtn'),
      onPressed: EasyDynamicTheme.of(context).changeTheme,
      icon: Icon(
        _getIcon(context),
      ),
      color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo : Colors.indigoAccent,
      iconSize: 36,
    );
  }
}
