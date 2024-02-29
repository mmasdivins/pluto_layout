import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'package:pluto_layout/src/pluto_layout_theme_data.dart';

import 'pluto_layout_data.dart';

/// ID according to the location of [PlutoLayoutContainer].
final layoutIdProvider = Provider<PlutoLayoutId>(
  (ref) => throw UnimplementedError(),
);

/// ID of [PlutoLayoutContainer] that currently has focus activated.
final focusedLayoutIdProvider = StateProvider<PlutoLayoutId>(
  (ref) => PlutoLayoutId.body,
);

/// Layout information of [PlutoLayout].
final layoutDataProvider = Provider((ref) => PlutoLayoutData());

/// Shortcut information defined by the user.
final layoutShortcutsProvider = Provider<PlutoLayoutShortcuts?>((ref) => null);


/// Theme data information
final layoutThemeProvider = Provider<PlutoLayoutThemeData?>((ref) => null);

/// Event controller for handling shortcut events, etc.
final layoutEventsProvider = Provider<PlutoLayoutEventStreamController>(
  (ref) => throw UnimplementedError(),
);
