import 'package:pluto_layout/pluto_layout.dart';

/// {@macro pluto_layout_action_items_changed_intent}
class PlutoItemsChangedEvent extends PlutoLayoutEvent {
  const PlutoItemsChangedEvent({
    required this.items,
  });

  final List<PlutoLayoutTabItem> items;
}
