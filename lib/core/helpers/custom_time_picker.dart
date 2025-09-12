import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

import '../services/theme_service.dart';

class CustomTimePicker extends StatelessWidget {
  const CustomTimePicker({
    Key? key,
    required this.isVisible,
    required this.onTap,
    required this.selectedTime,
    required this.label,
    this.isRequired = false,
  }) : super(key: key);

  final Function() onTap;
  final Rx<TimeOfDay> selectedTime;
  final RxBool isVisible;
  final String label;
  final bool? isRequired;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              label.tr,
              style: textTheme.copyWith(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor6
                    : AppColors.customGreyColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            isRequired!
                ? Text(
                    '*',
                    style: textTheme.copyWith(
                      color: Colors.red,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        SizedBox(height: 10.h),
        Obx(
          () => GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(selectedTime.value.hour % 12 == 0 ? 12 : selectedTime.value.hour % 12).toString().padLeft(2, '0')}:${selectedTime.value.minute.toString().padLeft(2, '0')} ${selectedTime.value.hour < 12 ? 'morning'.tr : 'evening'.tr}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor2
                                  : AppColors.customGreyColor5,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primaryColor,
                        size: 20.sp,
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.decelerate,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: child,
                        );
                      },
                      child: isVisible.value
                          ? Padding(
                              padding: EdgeInsets.only(top: 20.h),
                              child: OmniDateTimePicker(
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                is24HourMode: false,
                                isShowSeconds: false,
                                minutesInterval: 1,
                                amText: 'morning'.tr,
                                pmText: 'evening'.tr,
                                type: OmniDateTimePickerType.time,
                                onDateTimeChanged: (selectedTime) {
                                  this.selectedTime.value =
                                      TimeOfDay.fromDateTime(selectedTime);
                                },
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// class TimePicker extends StatefulWidget {
//   final TimeOfDay initialTime;
//   final ValueChanged<TimeOfDay> onTimeChanged;
//   final double size;
//   final Color textColor;

//   const TimePicker({
//     Key? key,
//     required this.initialTime,
//     required this.onTimeChanged,
//     this.size = 300,
//     this.textColor = Colors.black87,
//   }) : super(key: key);

//   @override
//   State<TimePicker> createState() => _CustomTimePickerState();
// }

// class _CustomTimePickerState extends State<TimePicker> {
//   late int _hour;
//   late int _minute;
//   bool _isAM = true;
//   bool _isHourSelection = true;

//   @override
//   void initState() {
//     super.initState();
//     _hour = widget.initialTime.hour;
//     _minute = widget.initialTime.minute;
//     _isAM = _hour < 12;
//   }

//   void _setHour(int hour) {
//     if (hour == 12) hour = 0;
//     if (!_isAM) hour += 12;
//     setState(() => _hour = hour);
//     _emitTimeChanged();
//   }

//   void _setMinute(int minute) {
//     setState(() => _minute = minute);
//     _emitTimeChanged();
//   }

//   void _emitTimeChanged() {
//     widget.onTimeChanged(TimeOfDay(hour: _hour, minute: _minute));
//   }

//   void _toggleAMPM(bool isAMSelected) {
//     if (_isAM != isAMSelected) {
//       setState(() {
//         _isAM = isAMSelected;
//         _hour = (_hour + 12) % 24;
//       });
//       _emitTimeChanged();
//     }
//   }

//   int get _displayHour {
//     int hour = _hour % 12;
//     return hour == 0 ? 12 : hour;
//   }

//   double _getHourAngle() => (_displayHour % 12) / 12 * 2 * math.pi;

//   double _getMinuteAngle() => _minute / 60 * 2 * math.pi;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         _buildHeader(context),
//         _buildClock(),
//         _buildFooter(),
//       ],
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     final period = _isAM ? 'morning'.tr : 'evening'.tr;
//     return Container(
//       height: 40.h,
//       color: AppColors.primaryColor,
//       alignment: Alignment.center,
//       child: Text(
//         '${_displayHour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} $period',
//         style: Theme.of(context).textTheme.bodyLarge!.copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//             ),
//       ),
//     );
//   }

//   Widget _buildClock() {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         _isHourSelection ? _buildHourSelection() : _buildMinuteSelection(),
//         Container(
//           width: 10.w,
//           height: 10.h,
//           decoration: const BoxDecoration(
//             color: AppColors.primaryColor,
//             shape: BoxShape.circle,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHourSelection() {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         for (int i = 1; i <= 12; i++) _buildClockNumber(i, isHour: true),
//         DraggableClockHand(
//           size: widget.size,
//           angle: _getHourAngle(),
//           color: AppColors.primaryColor,
//           onAngleChanged: (angle) {
//             int hour = ((angle / (2 * math.pi)) * 12).round() % 12;
//             _setHour(hour == 0 ? 12 : hour);
//           },
//           onDragEnd: () => setState(() => _isHourSelection = false),
//         ),
//       ],
//     );
//   }

//   Widget _buildMinuteSelection() {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         for (int i = 0; i < 60; i += 5) _buildClockNumber(i, isHour: false),
//         DraggableClockHand(
//           size: widget.size,
//           angle: _getMinuteAngle(),
//           color: AppColors.primaryColor,
//           onAngleChanged: (angle) {
//             int minute = ((angle / (2 * math.pi)) * 60).round() % 60;
//             _setMinute(minute);
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildClockNumber(int value, {required bool isHour}) {
//     final total = isHour ? 12 : 60;
//     final index = isHour ? value % 12 : value;
//     final angle = index / total * 2 * math.pi;
//     final radius = widget.size / 2 - 30;
//     final x = radius * math.sin(angle);
//     final y = -radius * math.cos(angle);

//     return Positioned(
//       left: widget.size / 2 - 20 + x,
//       top: widget.size / 2 - 20 + y,
//       child: GestureDetector(
//         onTap: () {
//           isHour ? _setHour(value) : _setMinute(value);
//           if (isHour) setState(() => _isHourSelection = false);
//         },
//         child: Container(
//           width: 40.w,
//           height: 40.h,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: isHour
//                 ? (_displayHour == value ? AppColors.primaryColor : null)
//                 : (_minute == value ? AppColors.primaryColor : null),
//           ),
//           child: Text(
//             value.toString().padLeft(2, '0'),
//             style: TextStyle(
//               color: isHour
//                   ? (_displayHour == value ? Colors.white : widget.textColor)
//                   : (_minute == value ? Colors.white : widget.textColor),
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFooter() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildToggle('morning', _isAM, () => _toggleAMPM(true)),
//         _buildToggle('evening', !_isAM, () => _toggleAMPM(false)),
//         _buildToggle('hour', _isHourSelection, () {
//           if (!_isHourSelection) setState(() => _isHourSelection = true);
//         }),
//         _buildToggle('minute', !_isHourSelection, () {
//           if (_isHourSelection) setState(() => _isHourSelection = false);
//         }),
//       ],
//     );
//   }

//   Widget _buildToggle(String label, bool isSelected, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: EdgeInsets.symmetric(vertical: 10.7.h),
//         padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primaryColor : Colors.grey[300],
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Text(
//           label.tr,
//           style: TextStyle(
//             color: isSelected ? Colors.white : widget.textColor,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class DraggableClockHand extends StatefulWidget {
//   final double size;
//   final double angle;
//   final Color color;
//   final ValueChanged<double> onAngleChanged;
//   final VoidCallback? onDragEnd;

//   const DraggableClockHand({
//     Key? key,
//     required this.size,
//     required this.angle,
//     required this.color,
//     required this.onAngleChanged,
//     this.onDragEnd,
//   }) : super(key: key);

//   @override
//   State<DraggableClockHand> createState() => _DraggableClockHandState();
// }

// class _DraggableClockHandState extends State<DraggableClockHand> {
//   late double _angle;
//   // متغير لتتبع ما إذا كان السحب أفقيًا
//   bool _isDraggingHorizontally = false;

//   @override
//   void initState() {
//     super.initState();
//     _angle = widget.angle;
//   }

//   @override
//   void didUpdateWidget(covariant DraggableClockHand oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.angle != widget.angle) _angle = widget.angle;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       // onPanDown: يتم استدعاؤه عند بدء اللمس
//       onPanDown: (_) {
//         _isDraggingHorizontally = false; // إعادة تعيين الحالة عند كل لمسة جديدة
//       },
//       onPanUpdate: (details) {
//         // details.delta يحتوي على مقدار التغير في المحورين X و Y
//         // إذا كان التغير الأفقي أكبر من الرأسي، نعتبره سحبًا أفقيًا
//         if (!_isDraggingHorizontally &&
//             details.delta.dx.abs() > details.delta.dy.abs()) {
//           _isDraggingHorizontally = true;
//         }

//         // فقط إذا كان السحب أفقيًا، قم بتحديث زاوية العقرب
//         if (_isDraggingHorizontally) {
//           final center = Offset(widget.size.w / 2, widget.size.h / 2);
//           final dx = details.localPosition.dx - center.dx;
//           final dy = details.localPosition.dy - center.dy;
//           final newAngle = math.atan2(dx, -dy);
//           final normalized = newAngle < 0 ? newAngle + 2 * math.pi : newAngle;
//           setState(() => _angle = normalized);
//           widget.onAngleChanged(normalized);
//         }
//       },
//       onPanEnd: (_) {
//         if (_isDraggingHorizontally) {
//           widget.onDragEnd?.call();
//         }
//         _isDraggingHorizontally = false; // إعادة تعيين الحالة عند انتهاء السحب
//       },
//       child: SizedBox(
//         width: widget.size.w,
//         height: widget.size.h,
//         child: CustomPaint(
//           painter: _ClockHandPainter(
//             angle: _angle,
//             color: widget.color,
//             length: widget.size.w / 2.w - 42.w,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ClockHandPainter extends CustomPainter {
//   final double angle;
//   final double length;
//   final Color color;

//   _ClockHandPainter({
//     required this.angle,
//     required this.length,
//     required this.color,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width.w / 2.w, size.height.h / 2.05.h);
//     final end = Offset(
//       center.dx + length * math.sin(angle),
//       center.dy - length * math.cos(angle),
//     );

//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = 2.w
//       ..strokeCap = StrokeCap.round;

//     canvas.drawLine(center, end, paint);
//     canvas.drawCircle(end, 4, Paint()..color = color);
//   }

//   @override
//   bool shouldRepaint(covariant _ClockHandPainter oldDelegate) {
//     return oldDelegate.angle != angle ||
//         oldDelegate.length != length ||
//         oldDelegate.color != color;
//   }
// }
