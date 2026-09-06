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
    required this.child,
  }) : super(key: key);

  final List<EmployeeCardSwipeAction> actions;
  final Widget child;

  @override
  State<EmployeeCardSwipe> createState() => _EmployeeCardSwipeState();
}

class _EmployeeCardSwipeState extends State<EmployeeCardSwipe> {
  static const double _actionWidth = 60;
  double _offset = 0;

  double get _revealWidth => widget.actions.length * (_actionWidth + 4);

  void _update(DragUpdateDetails details) {
    if (widget.actions.isEmpty) return;
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(0, _revealWidth);
    });
  }

  void _finish(DragEndDetails details) {
    if (widget.actions.isEmpty) return;
    final shouldOpen =
        _offset > _revealWidth * .25 || (details.primaryVelocity ?? 0) > 350;
    setState(() => _offset = shouldOpen ? _revealWidth : 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return widget.child;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 0,
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
            duration: const Duration(milliseconds: 180),
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

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({required this.action, required this.onTap});

  final EmployeeCardSwipeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color,
      borderRadius: BorderRadius.circular(4.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.r),
        child: SizedBox(
          width: _EmployeeCardSwipeState._actionWidth.w,
          height: 72.h,
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
