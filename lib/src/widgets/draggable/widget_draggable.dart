import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef DragAnchorStrategy = Offset Function(WidgetDraggable<Object> draggable, BuildContext context, Offset position);

Offset childDragAnchorStrategy(WidgetDraggable<Object> draggable, BuildContext context, Offset position) {
  final RenderBox renderObject = context.findRenderObject()! as RenderBox;
  return renderObject.globalToLocal(position);
}

class WidgetDraggable<T extends Object> extends StatefulWidget {
  const WidgetDraggable({
    Key? key,
    required this.child,
    required this.feedback,
    this.data,
    this.axis,
    this.childWhenDragging,
    this.feedbackOffset = Offset.zero,
    this.dragAnchorStrategy = childDragAnchorStrategy,
    this.affinity,
    this.maxSimultaneousDrags,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.ignoringFeedbackSemantics = true,
    this.ignoringFeedbackPointer = true,
    this.rootOverlay = false,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
  })  : assert(maxSimultaneousDrags == null || maxSimultaneousDrags >= 0),
        super(key: key);

  final T? data;
  final Axis? axis;
  final Widget child;
  final Widget? childWhenDragging;
  final Widget feedback;
  final Offset feedbackOffset;
  final DragAnchorStrategy dragAnchorStrategy;
  final bool ignoringFeedbackSemantics;
  final bool ignoringFeedbackPointer;
  final Axis? affinity;
  final int? maxSimultaneousDrags;
  final VoidCallback? onDragStarted;
  final DragUpdateCallback? onDragUpdate;
  final DraggableCanceledCallback? onDraggableCanceled;
  final VoidCallback? onDragCompleted;
  final DragEndCallback? onDragEnd;
  final bool rootOverlay;
  final HitTestBehavior hitTestBehavior;

  @protected
  MultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) {
    switch (affinity) {
      case Axis.horizontal:
        return HorizontalMultiDragGestureRecognizer()..onStart = onStart;
      case Axis.vertical:
        return VerticalMultiDragGestureRecognizer()..onStart = onStart;
      case null:
        return ImmediateMultiDragGestureRecognizer()..onStart = onStart;
    }
  }

  @override
  State<WidgetDraggable<T>> createState() => _WidgetDraggableState<T>();
}

class _WidgetDraggableState<T extends Object> extends State<WidgetDraggable<T>> {
  GestureRecognizer? recognizer;
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    recognizer = widget.createRecognizer(startDrag);
  }

  @override
  void dispose() {
    _disposeRecognizerIfInactive();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    recognizer!.gestureSettings = MediaQuery.maybeOf(context)?.gestureSettings;
    super.didChangeDependencies();
  }

  void _disposeRecognizerIfInactive() {
    if (_activeCount > 0) {
      return;
    }
    recognizer!.dispose();
    recognizer = null;
  }

  void routePointer(PointerDownEvent event) {
    if (widget.maxSimultaneousDrags != null && _activeCount >= widget.maxSimultaneousDrags!) {
      return;
    }
    recognizer!.addPointer(event);
  }

  _DragAvatar<T>? startDrag(Offset position) {
    if (widget.maxSimultaneousDrags != null && _activeCount >= widget.maxSimultaneousDrags!) {
      return null;
    }
    final Offset dragStartPoint;
    dragStartPoint = widget.dragAnchorStrategy(widget, context, position);
    setState(() {
      _activeCount += 1;
    });
    final _DragAvatar<T> avatar = _DragAvatar<T>(
      overlayState: Overlay.of(context, debugRequiredFor: widget, rootOverlay: widget.rootOverlay),
      data: widget.data,
      axis: widget.axis,
      initialPosition: position,
      dragStartPoint: dragStartPoint,
      feedback: widget.feedback,
      feedbackOffset: widget.feedbackOffset,
      ignoringFeedbackSemantics: widget.ignoringFeedbackSemantics,
      ignoringFeedbackPointer: widget.ignoringFeedbackPointer,
      onDragUpdate: (DragUpdateDetails details) {
        if (mounted && widget.onDragUpdate != null) {
          widget.onDragUpdate!(details);
        }
      },
      onDragEnd: (Velocity velocity, Offset offset, bool wasAccepted) {
        if (mounted) {
          setState(() {
            _activeCount -= 1;
          });
        } else {
          _activeCount -= 1;
          _disposeRecognizerIfInactive();
        }
        if (mounted && widget.onDragEnd != null) {
          widget.onDragEnd!(DraggableDetails(
            wasAccepted: wasAccepted,
            velocity: velocity,
            offset: offset,
          ));
        }
        if (wasAccepted && widget.onDragCompleted != null) {
          widget.onDragCompleted!();
        }
        if (!wasAccepted && widget.onDraggableCanceled != null) {
          widget.onDraggableCanceled!(velocity, offset);
        }
      },
    );
    widget.onDragStarted?.call();
    return avatar;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    final childWhenDragging = widget.childWhenDragging;
    final bool showChild = _activeCount == 0 || childWhenDragging == null;
    return showChild ? widget.child : childWhenDragging;
  }
}

class WidgetDragTarget<T extends Object> extends StatefulWidget {
  const WidgetDragTarget({
    Key? key,
    required this.builder,
    this.onWillAccept,
    this.onAccept,
    this.onAcceptWithDetails,
    this.onLeave,
    this.onMove,
    this.hitTestBehavior = HitTestBehavior.translucent,
  }) : super(key: key);
  final DragTargetBuilder<T> builder;
  final DragTargetWillAccept<T>? onWillAccept;
  final DragTargetAccept<T>? onAccept;
  final DragTargetAcceptWithDetails<T>? onAcceptWithDetails;
  final DragTargetLeave<T>? onLeave;
  final DragTargetMove<T>? onMove;
  final HitTestBehavior hitTestBehavior;

  @override
  State<WidgetDragTarget<T>> createState() => _DragTargetState<T>();
}

List<T?> _mapAvatarsToData<T extends Object>(List<_DragAvatar<Object>> avatars) {
  return avatars.map<T?>((_DragAvatar<Object> avatar) => avatar.data as T?).toList();
}

class _DragTargetState<T extends Object> extends State<WidgetDragTarget<T>> {
  final List<_DragAvatar<Object>> _candidateAvatars = <_DragAvatar<Object>>[];
  final List<_DragAvatar<Object>> _rejectedAvatars = <_DragAvatar<Object>>[];

  bool isExpectedDataType(Object? data, Type type) {
    if (kIsWeb && ((type == int && T == double) || (type == double && T == int))) {
      return false;
    }
    return data is T?;
  }

  bool didEnter(_DragAvatar<Object> avatar) {
    assert(!_candidateAvatars.contains(avatar));
    assert(!_rejectedAvatars.contains(avatar));
    if (widget.onWillAccept == null || widget.onWillAccept!(avatar.data as T?)) {
      setState(() {
        _candidateAvatars.add(avatar);
      });
      return true;
    } else {
      setState(() {
        _rejectedAvatars.add(avatar);
      });
      return false;
    }
  }

  void didLeave(_DragAvatar<Object> avatar) {
    assert(_candidateAvatars.contains(avatar) || _rejectedAvatars.contains(avatar));
    if (!mounted) {
      return;
    }
    setState(() {
      _candidateAvatars.remove(avatar);
      _rejectedAvatars.remove(avatar);
    });
    widget.onLeave?.call(avatar.data as T?);
  }

  void didDrop(_DragAvatar<Object> avatar) {
    assert(_candidateAvatars.contains(avatar));
    if (!mounted) {
      return;
    }
    setState(() {
      _candidateAvatars.remove(avatar);
    });
    widget.onAccept?.call(avatar.data! as T);
    widget.onAcceptWithDetails?.call(DragTargetDetails<T>(data: avatar.data! as T, offset: avatar._lastOffset!));
  }

  void didMove(_DragAvatar<Object> avatar) {
    if (!mounted) {
      return;
    }
    widget.onMove?.call(DragTargetDetails<T>(data: avatar.data! as T, offset: avatar._lastOffset!));
  }

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: this,
      behavior: widget.hitTestBehavior,
      child: widget.builder(context, _mapAvatarsToData<T>(_candidateAvatars), _mapAvatarsToData<Object>(_rejectedAvatars)),
    );
  }
}

enum _DragEndKind { dropped, canceled }

typedef _OnDragEnd = void Function(Velocity velocity, Offset offset, bool wasAccepted);

class _DragAvatar<T extends Object> extends Drag {
  _DragAvatar({
    required this.overlayState,
    this.data,
    this.axis,
    required Offset initialPosition,
    this.dragStartPoint = Offset.zero,
    this.feedback,
    this.feedbackOffset = Offset.zero,
    this.onDragUpdate,
    this.onDragEnd,
    required this.ignoringFeedbackSemantics,
    required this.ignoringFeedbackPointer,
  }) : _position = initialPosition {
    _entry = OverlayEntry(builder: _build);
    overlayState.insert(_entry!);
    updateDrag(initialPosition);
  }

  final T? data;
  final Axis? axis;
  final Offset dragStartPoint;
  final Widget? feedback;
  final Offset feedbackOffset;
  final DragUpdateCallback? onDragUpdate;
  final _OnDragEnd? onDragEnd;
  final OverlayState overlayState;
  final bool ignoringFeedbackSemantics;
  final bool ignoringFeedbackPointer;

  _DragTargetState<Object>? _activeTarget;
  final List<_DragTargetState<Object>> _enteredTargets = <_DragTargetState<Object>>[];
  Offset _position;
  Offset? _lastOffset;
  OverlayEntry? _entry;

  @override
  void update(DragUpdateDetails details) {
    final Offset oldPosition = _position;
    _position += _restrictAxis(details.delta);
    updateDrag(_position);
    if (onDragUpdate != null && _position != oldPosition) {
      onDragUpdate!(details);
    }
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(_DragEndKind.dropped, _restrictVelocityAxis(details.velocity));
  }

  @override
  void cancel() {
    finishDrag(_DragEndKind.canceled);
  }

  void updateDrag(Offset globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
    _entry!.markNeedsBuild();
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition + feedbackOffset);

    final List<_DragTargetState<Object>> targets = _getDragTargets(result.path).toList();

    bool listsMatch = false;
    if (targets.length >= _enteredTargets.length && _enteredTargets.isNotEmpty) {
      listsMatch = true;
      final Iterator<_DragTargetState<Object>> iterator = targets.iterator;
      for (int i = 0; i < _enteredTargets.length; i += 1) {
        iterator.moveNext();
        if (iterator.current != _enteredTargets[i]) {
          listsMatch = false;
          break;
        }
      }
    }

    if (listsMatch) {
      for (final _DragTargetState<Object> target in _enteredTargets) {
        target.didMove(this);
      }
      return;
    }

    _leaveAllEntered();

    final _DragTargetState<Object>? newTarget = targets.cast<_DragTargetState<Object>?>().firstWhere(
          (_DragTargetState<Object>? target) {
        if (target == null) {
          return false;
        }
        _enteredTargets.add(target);
        return target.didEnter(this);
      },
      orElse: () => null,
    );

    // Report moves to the targets.
    for (final _DragTargetState<Object> target in _enteredTargets) {
      target.didMove(this);
    }

    _activeTarget = newTarget;
  }

  Iterable<_DragTargetState<Object>> _getDragTargets(Iterable<HitTestEntry> path) {
    final List<_DragTargetState<Object>> targets = <_DragTargetState<Object>>[];
    for (final HitTestEntry entry in path) {
      final HitTestTarget target = entry.target;
      if (target is RenderMetaData) {
        final dynamic metaData = target.metaData;
        if (metaData is _DragTargetState && metaData.isExpectedDataType(data, T)) {
          targets.add(metaData);
        }
      }
    }
    return targets;
  }

  void _leaveAllEntered() {
    for (int i = 0; i < _enteredTargets.length; i += 1) {
      _enteredTargets[i].didLeave(this);
    }
    _enteredTargets.clear();
  }

  void finishDrag(_DragEndKind endKind, [Velocity? velocity]) {
    bool wasAccepted = false;
    if (endKind == _DragEndKind.dropped && _activeTarget != null) {
      _activeTarget!.didDrop(this);
      wasAccepted = true;
      _enteredTargets.remove(_activeTarget);
    }
    _leaveAllEntered();
    _activeTarget = null;
    _entry!.remove();
    _entry = null;
    onDragEnd?.call(velocity ?? Velocity.zero, _lastOffset!, wasAccepted);
  }

  Widget _build(BuildContext context) {
    final RenderBox box = overlayState.context.findRenderObject()! as RenderBox;
    final Offset overlayTopLeft = box.localToGlobal(Offset.zero);
    return Positioned(
      left: _lastOffset!.dx - overlayTopLeft.dx,
      top: _lastOffset!.dy - overlayTopLeft.dy,
      child: IgnorePointer(
        ignoring: ignoringFeedbackPointer,
        ignoringSemantics: ignoringFeedbackSemantics,
        child: feedback,
      ),
    );
  }

  Velocity _restrictVelocityAxis(Velocity velocity) {
    if (axis == null) {
      return velocity;
    }
    return Velocity(
      pixelsPerSecond: _restrictAxis(velocity.pixelsPerSecond),
    );
  }

  Offset _restrictAxis(Offset offset) {
    if (axis == null) {
      return offset;
    }
    if (axis == Axis.horizontal) {
      return Offset(offset.dx, 0.0);
    }
    return Offset(0.0, offset.dy);
  }
}

class WidgetDraggableSource extends StatefulWidget {
  final Widget child;

  const WidgetDraggableSource({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<WidgetDraggableSource> {
  _WidgetDraggableState? draggableState;

  @override
  void initState() {
    super.initState();
    draggableState = context.findAncestorStateOfType<_WidgetDraggableState>();
  }

  @override
  Widget build(BuildContext context) {
    final draggableState = this.draggableState;
    if (draggableState == null) return widget.child;
    final bool canDrag =
        draggableState.widget.maxSimultaneousDrags == null || draggableState._activeCount < draggableState.widget.maxSimultaneousDrags!;
    return Listener(
      behavior: draggableState.widget.hitTestBehavior,
      onPointerDown: canDrag ? draggableState.routePointer : null,
      child: widget.child,
    );
  }
}