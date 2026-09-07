import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmployeePointSwipeAction {
  const EmployeePointSwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class EmployeePointSwipeCard extends StatefulWidget {
  const EmployeePointSwipeCard({
    Key? key,
    required this.child,
    this.startActions = const <EmployeePointSwipeAction>[],
    this.endActions = const <EmployeePointSwipeAction>[],
  }) : super(key: key);

  final Widget child;
  final List<EmployeePointSwipeAction> startActions;
  final List<EmployeePointSwipeAction> endActions;

  @override
  State<EmployeePointSwipeCard> createState() => _EmployeePointSwipeCardState();
}

class _EmployeePointSwipeCardState extends State<EmployeePointSwipeCard> {
  double _offset = 0;
  static const double _dragResistance = .65;
  static const Duration _settleDuration = Duration(milliseconds: 320);

  double _widthFor(List<EmployeePointSwipeAction> actions) {
    if (actions.isEmpty) return 0;
    return actions.length * 66.w + (actions.length - 1) * 5.w;
  }

  void _update(DragUpdateDetails details) {
    final next = _offset + details.delta.dx * _dragResistance;
    final maxPositive = _widthFor(widget.startActions);
    final maxNegative = _widthFor(widget.endActions);
    setState(() => _offset = next.clamp(-maxNegative, maxPositive));
  }

  void _finish(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final actions = _offset >= 0 ? widget.startActions : widget.endActions;
    final revealWidth = _widthFor(actions);
    if (revealWidth == 0) {
      setState(() => _offset = 0);
      return;
    }
    final shouldOpen =
        _offset.abs() > revealWidth * .34 || velocity.abs() > 500;
    setState(() {
      _offset = shouldOpen ? (_offset >= 0 ? revealWidth : -revealWidth) : 0;
    });
  }

  void _run(EmployeePointSwipeAction action) {
    setState(() => _offset = 0);
    action.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final actions = _offset >= 0 ? widget.startActions : widget.endActions;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Stack(
        alignment: _offset >= 0 ? Alignment.centerLeft : Alignment.centerRight,
        children: [
          Positioned.fill(
            child: Align(
              alignment:
                  _offset >= 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(actions.length, (index) {
                  final action = actions[index];
                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: index == actions.length - 1 ? 0 : 5.w,
                    ),
                    child: _SwipeActionTile(
                      action: action,
                      onTap: () => _run(action),
                    ),
                  );
                }),
              ),
            ),
          ),
          AnimatedContainer(
            duration: _settleDuration,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: _update,
              onHorizontalDragEnd: _finish,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionTile extends StatelessWidget {
  const _SwipeActionTile({required this.action, required this.onTap});

  final EmployeePointSwipeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: action.color,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            width: 66.w,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: Colors.white, size: 22.sp),
                SizedBox(height: 5.h),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
