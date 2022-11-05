part of pluto_layout_tabs;

class _Menus extends ConsumerStatefulWidget {
  const _Menus({
    required this.direction,
    required this.mode,
    bool? draggable,
    required this.menuKey,
  })  : draggable = draggable ?? false,
        super(key: const ValueKey('_Menus'));

  final PlutoLayoutContainerDirection direction;

  final PlutoLayoutTabMode mode;

  final bool draggable;

  final GlobalKey<_MenusState> menuKey;

  @override
  ConsumerState<_Menus> createState() => _MenusState();
}

class _MenusState extends ConsumerState<_Menus> {
  late final StreamSubscription<PlutoLayoutEvent> _eventListener;

  @override
  void initState() {
    super.initState();

    final events = ref.read(layoutEventsProvider);

    _eventListener = events.listen(handleEvent);
  }

  @override
  void dispose() {
    _eventListener.cancel();

    super.dispose();
  }

  MainAxisAlignment getMenuAlignment(PlutoLayoutId id) {
    switch (id) {
      case PlutoLayoutId.top:
        return MainAxisAlignment.start;
      case PlutoLayoutId.left:
        return MainAxisAlignment.end;
      case PlutoLayoutId.right:
        return MainAxisAlignment.start;
      case PlutoLayoutId.bottom:
        return MainAxisAlignment.start;
      case PlutoLayoutId.body:
        return MainAxisAlignment.start;
    }
  }

  int getMenuRotate(PlutoLayoutId id) {
    switch (id) {
      case PlutoLayoutId.top:
        return 0;
      case PlutoLayoutId.left:
        return -45;
      case PlutoLayoutId.right:
        return 45;
      case PlutoLayoutId.bottom:
        return 0;
      case PlutoLayoutId.body:
        return 0;
    }
  }

  void handleEvent(PlutoLayoutEvent event) {
    // todo : refactor.
    if (event is PlutoToggleTabViewEvent &&
        event.containerDirection == widget.direction) {
      final item = ref
          .read(_itemsProvider)
          .firstWhereOrNull((e) => e.id == event.tabItemId);

      if (item == null) return;

      toggleTab(ref, item, !item.enabled);
    } else if (event is PlutoRotateTabViewEvent &&
        event.containerDirection == widget.direction) {
      final items = ref.read(_itemsProvider);

      if (items.isEmpty) return;

      if (items.length == 1) {
        toggleTab(ref, items.first, !items.first.enabled);
        return;
      }

      final enabledIndex = items.indexWhere((e) => e.enabled);

      if (enabledIndex == -1) {
        toggleTab(ref, items.first, true);
        return;
      }

      if (enabledIndex == items.length - 1) {
        toggleTab(
          ref,
          widget.mode.isShowOneMust ? items.first : items.last,
          widget.mode.isShowOneMust ? true : false,
        );
        return;
      }

      toggleTab(ref, items[enabledIndex + 1], true, forceShowOne: true);
    } else if (event is PlutoHideAllTabViewEvent) {
      ref.read(_itemsProvider.notifier).toggleAll(false, widget.mode);

      if (event.afterFocusToBody) {
        ref.read(layoutFocusedIdProvider.notifier).state = PlutoLayoutId.body;
      }
    } else if (event is PlutoRemoveTabItemEvent) {
      final layoutId = ref.read(layoutIdProvider);

      if (layoutId != event.layoutId) return;

      ref.read(_itemsProvider.notifier).remove(event.item);
    }
  }

  void toggleTab(
    WidgetRef ref,
    PlutoLayoutTabItem item,
    bool flag, {
    bool? forceShowOne,
  }) {
    if (widget.mode.isShowOneMust) flag = true;

    final layoutId = ref.read(layoutIdProvider);

    ref.read(layoutFocusedIdProvider.notifier).state = layoutId;

    final layoutData = ref.read(layoutDataProvider);

    ref.read(_itemsProvider.notifier).setEnabled(
          item.id,
          flag,
          widget.mode,
          forceShowOne: forceShowOne,
        );

    final items = ref.read(_itemsProvider).where((e) => e.enabled);

    final maxSize = layoutData.getMaxTabItemViewSize(layoutId);

    PlutoLayoutTabItemSizeResolver._update(
      maxSize: maxSize,
      minSize: PlutoLayoutData.minTabSize,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final layoutId = ref.read(layoutIdProvider);

    final items = ref.watch(_itemsProvider);

    final quarterTurns = getMenuRotate(layoutId);

    Widget draggableOrNot(PlutoLayoutTabItem item) {
      final button = ToggleButton(
        title: item.title,
        icon: item.icon,
        enabled: item.enabled,
        changed: (flag) => toggleTab(ref, item, flag),
      );

      if (!widget.draggable) return button;

      return _Draggable(
        layoutId: layoutId,
        item: item,
        items: items,
        mode: widget.mode,
        direction: widget.direction,
        quarterTurns: quarterTurns,
        child: button,
      );
    }

    final children = <Widget>[
      for (final item in (widget.direction.isLeft ? items.reversed : items))
        draggableOrNot(item)
    ];

    return Align(
      key: widget.menuKey,
      alignment: widget.direction.isVertical
          ? Alignment.centerLeft
          : Alignment.topCenter,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: SingleChildScrollView(
          reverse: widget.direction.isLeft,
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: getMenuAlignment(layoutId),
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Draggable extends ConsumerWidget {
  const _Draggable({
    required this.layoutId,
    required this.item,
    required this.items,
    required this.mode,
    required this.direction,
    required this.quarterTurns,
    required this.child,
  });

  final PlutoLayoutId layoutId;

  final PlutoLayoutTabItem item;

  final List<PlutoLayoutTabItem> items;

  final PlutoLayoutTabMode mode;

  final PlutoLayoutContainerDirection direction;

  final int quarterTurns;

  final Widget child;

  bool _onWillAccept(_DragData? data) {
    return data != null && data.item.id != item.id;
  }

  void Function(_DragData) _onAccept(WidgetRef ref) {
    final itemsNotifier = ref.read(_itemsProvider.notifier);

    return (data) {
      final index = items.indexOf(item);
      if (data.layoutId == layoutId) {
        itemsNotifier.remove(data.item);
      } else {
        final events = ref.read(layoutEventsProvider);
        events.add(PlutoRemoveTabItemEvent(data.layoutId, data.item));
      }
      itemsNotifier.insert(index, data.item);
      if (mode.isShowOneMode &&
          data.item.enabled &&
          items.where((e) => e.enabled).isNotEmpty) {
        itemsNotifier.setEnabled(data.item.id, true, mode);
      }
    };
  }

  Widget _builder(
    BuildContext context,
    List<_DragData?> candidateData,
    List<dynamic> rejectedData,
  ) {
    if (candidateData.isNotEmpty || rejectedData.isNotEmpty) {
      return ColoredBox(
        color: Theme.of(context).backgroundColor,
        child: child,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<_DragData>(
      data: _DragData(layoutId, item),
      dragAnchorStrategy: _childDragAnchorStrategy(direction),
      feedback: Material(
        child: RotatedBox(quarterTurns: quarterTurns, child: child),
      ),
      child: DragTarget<_DragData>(
        onWillAccept: _onWillAccept,
        onAccept: _onAccept(ref),
        builder: _builder,
      ),
    );
  }
}

class _DragData {
  const _DragData(this.layoutId, this.item);

  final PlutoLayoutId layoutId;

  final PlutoLayoutTabItem item;
}

Offset Function(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) _childDragAnchorStrategy(PlutoLayoutContainerDirection direction) {
  return (
    Draggable<Object> draggable,
    BuildContext context,
    Offset position,
  ) {
    final RenderBox renderObject = context.findRenderObject()! as RenderBox;
    final local = renderObject.globalToLocal(position);
    return _directionalPosition(local, renderObject.size, direction);
  };
}

Offset _directionalPosition(
  Offset offset,
  Size size,
  PlutoLayoutContainerDirection direction,
) {
  switch (direction) {
    case PlutoLayoutContainerDirection.top:
      return offset;
    case PlutoLayoutContainerDirection.left:
      return Offset(offset.dy, (size.width - offset.dx).abs());
    case PlutoLayoutContainerDirection.right:
      return Offset((size.height - offset.dy).abs(), offset.dx);
    case PlutoLayoutContainerDirection.bottom:
      return offset;
  }
}
