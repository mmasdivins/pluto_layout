part of pluto_layout;

/// Shortcut registration type of [PlutoLayout.shortcuts].
typedef PlutoLayoutShortcuts = Map<ShortcutActivator, PlutoLayoutIntent>;

/// [PlutoLayout] is a UI package that can configure a menu or tab view on each side.
///
/// {@template pluto_layout_example}
/// Check the example code.
/// https://github.com/bosskmk/pluto_layout/blob/main/example/lib/main.dart
///
/// Check out the web demo distributed with the example code.
/// https://weblaze.dev/pluto_layout/build/web/#/
/// {@endtemplate}
///
/// The [body], [top], [left], [right], [bottom] properties must pass a [PlutoLayoutContainer] as a child.
/// [body] must be passed. The rest of the properties can be optionally passed.
///
/// You can configure tab views by passing [PlutoLayoutTabs] as children of [PlutoLayoutContainer].
class PlutoLayout extends StatefulWidget {
  const PlutoLayout({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.body,
    this.shortcuts,
    this.plutoLayoutTheme,
    super.key,
  });

  /// You can configure tab views or menus at the top.
  final PlutoLayoutContainer? top;

  /// You can configure tab views and menus on the left side.
  final PlutoLayoutContainer? left;

  /// You can configure tab views or menus on the right side.
  final PlutoLayoutContainer? right;

  /// You can configure tab views or menus at the bottom.
  final PlutoLayoutContainer? bottom;

  /// This is the basic body screen.
  final PlutoLayoutContainer body;

  /// Create a ThemeData that's used to configure a Theme.
  final PlutoLayoutThemeData? plutoLayoutTheme;

  /// Specific actions by user registration shortcut keys
  ///
  /// {@template pluto_layout_shortcuts_example}
  /// ```dart
  /// shortcuts: {
  ///   LogicalKeySet(LogicalKeyboardKey.escape):
  ///       PlutoLayoutActions.hideAllTabView(),
  ///   LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1):
  ///       PlutoLayoutActions.rotateTabView(
  ///     PlutoLayoutContainerDirection.left,
  ///   ),
  ///   LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2):
  ///       PlutoLayoutActions.rotateTabView(
  ///     PlutoLayoutContainerDirection.right,
  ///   ),
  ///   LogicalKeySet(
  ///           LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight):
  ///       PlutoLayoutActions.increaseTabView(),
  ///   LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft):
  ///       PlutoLayoutActions.decreaseTabView(),
  /// },
  /// ```
  /// {@endtemplate}
  final PlutoLayoutShortcuts? shortcuts;

  @override
  State<PlutoLayout> createState() => _PlutoLayoutState();

  /// [PlutoLayoutEventStreamController] to receive or emit events of [PlutoLayout].
  ///
  /// You can access [BuildContext] from child widgets of [PlutoLayout].
  static PlutoLayoutEventStreamController? getEventStreamController(
      BuildContext context) {
    return context
        .findRootAncestorStateOfType<_PlutoLayoutState>()
        ?._eventStreamController;
  }
}

class _PlutoLayoutState extends State<PlutoLayout> {
  final PlutoLayoutEventStreamController _eventStreamController =
      PlutoLayoutEventStreamController();

  @override
  void dispose() {
    _eventStreamController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget layoutWidget = ProviderScope(
      overrides: [
        layoutShortcutsProvider.overrideWithValue(widget.shortcuts),
        layoutThemeProvider.overrideWithValue(widget.plutoLayoutTheme),
        layoutEventsProvider.overrideWithValue(_eventStreamController),
      ],
      child: _LayoutWidget(
        body: widget.body,
        eventStreamController: _eventStreamController,
        top: widget.top,
        left: widget.left,
        right: widget.right,
        bottom: widget.bottom,
      ),
    );

    if (widget.shortcuts != null) {
      layoutWidget = Shortcuts(
        shortcuts: widget.shortcuts!,
        debugLabel: 'PlutoLayout Shortcuts',
        child: layoutWidget,
      );
    }

    return layoutWidget;
  }
}

class _LayoutWidget extends ConsumerStatefulWidget {
  const _LayoutWidget({
    required this.body,
    required this.eventStreamController,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final PlutoLayoutContainer body;

  final PlutoLayoutContainer? top;

  final PlutoLayoutContainer? left;

  final PlutoLayoutContainer? right;

  final PlutoLayoutContainer? bottom;

  final PlutoLayoutEventStreamController eventStreamController;

  @override
  ConsumerState<_LayoutWidget> createState() => _LayoutWidgetState();
}

class _LayoutWidgetState extends ConsumerState<_LayoutWidget> {
  late final StreamSubscription<PlutoLayoutEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.eventStreamController.listen(_eventListener);
  }

  @override
  void dispose() {
    _subscription.cancel();

    super.dispose();
  }

  void _eventListener(PlutoLayoutEvent event) {
    if (event is PlutoRotateFocusedContainerEvent) {
      _handleRotateFocusedContainer(event);
    }
  }

  void _handleRotateFocusedContainer(PlutoRotateFocusedContainerEvent event) {
    final focusedLayoutId = ref.read(focusedLayoutIdProvider);

    final tabs =
        (event.reverse ? event.order.reversed : event.order).where((e) {
      switch (e) {
        case PlutoLayoutId.top:
          return widget.top != null;
        case PlutoLayoutId.left:
          return widget.left != null;
        case PlutoLayoutId.right:
          return widget.right != null;
        case PlutoLayoutId.bottom:
          return widget.bottom != null;
        case PlutoLayoutId.body:
          return true;
      }
    });

    if (tabs.length <= 1) return;

    final found = tabs.skipWhile((value) => value != focusedLayoutId);

    final PlutoLayoutId nextFocus =
        found.length <= 1 ? tabs.first : found.skip(1).first;

    ref.read(focusedLayoutIdProvider.notifier).state = nextFocus;
  }

  @override
  Widget build(BuildContext context) {
    final layoutData = ref.read(layoutDataProvider);

    final frontId = ref.watch(focusedLayoutIdProvider);
    final dragging = ref.watch(draggingStateProvider);
    return Stack(
      children: [
        CustomMultiChildLayout(
          delegate: _PlutoLayoutDelegate(layoutData, widget.eventStreamController),
          children: <LayoutId>[
            LayoutId(
              id: PlutoLayoutId.body,
              child: _LayoutIdProviderScope(
                id: PlutoLayoutId.body,
                child: widget.body,
              ),
            ),
            if (widget.right != null)
              LayoutId(
                id: PlutoLayoutId.right,
                child: _LayoutIdProviderScope(
                  id: PlutoLayoutId.right,
                  child: widget.right!,
                ),
              ),
            if (widget.left != null)
              LayoutId(
                id: PlutoLayoutId.left,
                child: _LayoutIdProviderScope(
                  id: PlutoLayoutId.left,
                  child: widget.left!,
                ),
              ),
            if (widget.bottom != null)
              LayoutId(
                id: PlutoLayoutId.bottom,
                child: _LayoutIdProviderScope(
                  id: PlutoLayoutId.bottom,
                  child: widget.bottom!,
                ),
              ),
            if (widget.top != null)
              LayoutId(
                id: PlutoLayoutId.top,
                child: _LayoutIdProviderScope(
                  id: PlutoLayoutId.top,
                  child: widget.top!,
                ),
              ),
          ]..sort((a, b) => a.id == frontId ? 1 : -1),
        ),
        // if (dragging != null)
        //   Container(
        //     alignment: Alignment.center,
        //     child: SizedBox(
        //       width: 200,
        //       height: 200,
        //       child: Stack(
        //         children: [
        //           // TOP
        //           Positioned(
        //               left: 75,
        //               top: 0,
        //               width: 50,
        //               height: 50,
        //               child: DragTarget(
        //                 onAccept: (data) {
        //                   int br = 0;
        //                 },
        //                 builder: (context, accepted, rejected) {
        //                   return  Container(
        //                     color: Colors.deepPurple,
        //                   );
        //                 },
        //               )
        //           ),
        //
        //           // LEFT
        //           Positioned(
        //             left: 0,
        //             top: 75,
        //             width: 50,
        //             height: 50,
        //             child: DragTarget(
        //               onAccept: (data) {
        //                 int br = 0;
        //               },
        //               builder: (context, accepted, rejected) {
        //                 return  Container(
        //                   color: Colors.red,
        //                 );
        //               },
        //             )
        //           ),
        //
        //           // CENTER
        //           Positioned(
        //               left: 75,
        //               top: 75,
        //               width: 50,
        //               height: 50,
        //               child: DragTarget(
        //                 onAccept: (data) {
        //                   int br = 0;
        //                 },
        //                 builder: (context, accepted, rejected) {
        //                   return  Container(
        //                     color: Colors.blue,
        //                   );
        //                 },
        //               )
        //           ),
        //
        //           // RIGHT
        //           Positioned(
        //               right: 0,
        //               top: 75,
        //               width: 50,
        //               height: 50,
        //               child: DragTarget(
        //                 onAccept: (data) {
        //                   int br = 0;
        //                 },
        //                 builder: (context, accepted, rejected) {
        //                   return  Container(
        //                     color: Colors.yellow,
        //                   );
        //                 },
        //               )
        //           ),
        //
        //           // BOTTOM
        //           Positioned(
        //               left: 75,
        //               bottom: 0,
        //               width: 50,
        //               height: 50,
        //               child: DragTarget(
        //                 onAccept: (data) {
        //                   int br = 0;
        //                 },
        //                 builder: (context, accepted, rejected) {
        //                   return  Container(
        //                     color: Colors.green,
        //                   );
        //                 },
        //               )
        //           ),
        //
        //         ],
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}

class _PlutoLayoutDelegate extends MultiChildLayoutDelegate {
  _PlutoLayoutDelegate(this._size, this._events,);

  final PlutoLayoutData _size;

  final PlutoLayoutEventStreamController _events;

  @override
  void performLayout(Size size) {

    _relayoutEvent(size);

    _size.size = size;

    PlutoLayoutId id = PlutoLayoutId.top;
    if (hasChild(id)) {
      _size.topSize = layoutChild(id, BoxConstraints.loose(size));
      positionChild(id, Offset.zero);
    }

    id = PlutoLayoutId.bottom;
    if (hasChild(id)) {
      _size.bottomSize = layoutChild(id, BoxConstraints.loose(size));
      positionChild(id, Offset(0, size.height - _size.bottomSize.height));
    }

    id = PlutoLayoutId.left;
    if (hasChild(id)) {
      _size.leftSize = layoutChild(
        id,
        BoxConstraints.loose(
          Size(
            size.width,
            max(
              size.height - _size.topSize.height - _size.bottomSize.height,
              0,
            ),
          ),
        ),
      );
      positionChild(id, Offset(0, _size.topSize.height));
    }

    id = PlutoLayoutId.right;
    if (hasChild(id)) {
      _size.rightSize = layoutChild(
        id,
        BoxConstraints.loose(
          Size(
            size.width,
            max(
              size.height - _size.topSize.height - _size.bottomSize.height,
              0,
            ),
          ),
        ),
      );
      positionChild(
        id,
        Offset(size.width - _size.rightSize.width, _size.topSize.height),
      );
    }

    id = PlutoLayoutId.body;
    if (hasChild(id)) {
      final double minSize = _size.bodyTabMenuSize.height;

      _size.bodySize = layoutChild(
        id,
        BoxConstraints.tight(Size(
          max(size.width - _size.leftSize.width - _size.rightSize.width, 0),
          max(
            size.height - _size.topSize.height - _size.bottomSize.height,
            minSize,
          ),
        )),
      );
      positionChild(id, Offset(_size.leftSize.width, _size.topSize.height));
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return true;
  }

  void _relayoutEvent(Size size) {
    if (_size.size == Size.zero) return;
    if (_size.size == size) return;

    _events.add(const PlutoRelayoutEvent());
  }
}

class _LayoutIdProviderScope extends StatelessWidget {
  const _LayoutIdProviderScope({
    required this.id,
    required this.child,
  });

  final PlutoLayoutId id;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [layoutIdProvider.overrideWithValue(id)],
      child: child,
    );
  }
}

/// [PlutoLayoutContainer] ID by position of the widget.
enum PlutoLayoutId {
  top,
  left,
  body,
  right,
  bottom;

  bool get isTop => this == PlutoLayoutId.top;
  bool get isLeft => this == PlutoLayoutId.left;
  bool get isBody => this == PlutoLayoutId.body;
  bool get isRight => this == PlutoLayoutId.right;
  bool get isBottom => this == PlutoLayoutId.bottom;
}
