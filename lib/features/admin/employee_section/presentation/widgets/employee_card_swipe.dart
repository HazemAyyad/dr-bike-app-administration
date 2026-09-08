import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmployeeCardSwipeAction {
  const EmployeeCardSwipeAction({
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

class EmployeeCardSwipe extends StatefulWidget {
  const EmployeeCardSwipe({
    Key? key,
    required this.actions,
    required this.backgroundColor,
    required this.child,
  }) : super(key: key);

  final List<EmployeeCardSwipeAction> actions;
  final Color backgroundColor;
  final Widget child;

  @override
  State<EmployeeCardSwipe> createState() => _EmployeeCardSwipeState();
}

class _EmployeeCardSwipeState extends State<EmployeeCardSwipe> {
  static const double _actionWidth = 60;
  static const double _dragResistance = .65;
  static const Duration _settleDuration = Duration(milliseconds: 320);
  double _offset = 0;

  double get _revealWidth => widget.actions.length * (_actionWidth + 4);

  void _update(DragUpdateDetails details) {
    if (widget.actions.isEmpty) return;
    setState(() {
      _offset = (_offset + details.delta.dx * _dragResistance)
          .clamp(-_revealWidth, _revealWidth);
    });
  }

  void _finish(DragEndDetails details) {
    if (widget.actions.isEmpty) return;
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen =
        _offset.abs() > _revealWidth * .32 || velocity.abs() > 500;
    setState(() {
      if (!shouldOpen) {
        _offset = 0;
      } else {
        final direction = velocity.abs() > 500 ? velocity.sign : _offset.sign;
        _offset = direction * _revealWidth;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return widget.child;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        alignment: _offset >= 0 ? Alignment.centerLeft : Alignment.centerRight,
        children: [
          Positioned(
            left: _offset >= 0 ? 0 : null,
            right: _offset < 0 ? 0 : null,
            child: Row(
              children: widget.actions
                  .map(
                    (action) => Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: _SwipeAction(
                        action: action,
                        onTap: () {
                          setState(() => _offset = 0);
                          action.onTap();
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          AnimatedContainer(
            duration: _settleDuration,
            curve: Curves.easeOut,
            color: widget.backgroundColor,
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

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({required this.action, required this.onTap});

  final EmployeeCardSwipeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: SizedBox(
          width: _EmployeeCardSwipeState._actionWidth.w,
          height: 74.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: Colors.white, size: 19.sp),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
