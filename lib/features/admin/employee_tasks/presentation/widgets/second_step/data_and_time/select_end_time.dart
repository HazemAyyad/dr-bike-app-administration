import 'package:doctorbike/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../../../../../../../core/utils/app_colors.dart';

class EndTimePickerController extends GetxController {
//   final createTaskController = Get.put(
//  CreateTaskController(
//       creatSpecialTasksUsecase: CreatSpecialTasksUsecase(
//         adminRepository: Get.find<AdminImplement>(),
//       ),
//     ),
//   );
  final Rx<TimeOfDay> selectEndTime = TimeOfDay.now().obs;
  final RxBool isAM = true.obs;
  final RxBool isHourSelection = true.obs;

  void setHour(int hour) {
    if (hour == 12) {
      hour = 0;
    }
    if (!isAM.value) {
      hour += 12;
    }
    selectEndTime.value =
        TimeOfDay(hour: hour, minute: selectEndTime.value.minute);
  }

  void setMinute(int minute) {
    selectEndTime.value =
        TimeOfDay(hour: selectEndTime.value.hour, minute: minute);
  }

  void toggleAMPM() {
    isAM.toggle();
    int hour = selectEndTime.value.hour;
    if (isAM.value && hour >= 12) {
      hour -= 12;
    } else if (!isAM.value && hour < 12) {
      hour += 12;
    }
    selectEndTime.value =
        TimeOfDay(hour: hour, minute: selectEndTime.value.minute);
  }

  void toggleHourMinuteSelection() {
    isHourSelection.toggle();
  }

  int get displayHour {
    int hour = selectEndTime.value.hour;
    if (hour == 0) return 12;
    if (hour > 12) return hour - 12;
    return hour;
  }

  String get period => isAM.value ? 'morning'.tr : 'evening'.tr;

  String get formattedTime {
    return '${displayHour.toString().padLeft(2, '0')}:${selectEndTime.value.minute.toString().padLeft(2, '0')} $period';
  }
}

class TimePicker extends StatelessWidget {
  final EndTimePickerController controller;
  final double size;
  final Color primaryColor;
  final Color textColor;
  final VoidCallback? onDone;

  TimePicker({
    Key? key,
    EndTimePickerController? controller,
    this.size = 350,
    this.primaryColor = AppColors.primaryColor,
    this.textColor = Colors.black87,
    this.onDone,
  })  : controller = controller ?? Get.put(EndTimePickerController()),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        SizedBox(height: 20.h),
        _buildClock(),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(color: primaryColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(
            () => Text(
              controller.formattedTime,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.whiteColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClock() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Clock face
        Obx(
          () => controller.isHourSelection.value
              ? _buildHourSelection()
              : _buildMinuteSelection(),
        ),

        // Center dot
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildHourSelection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Hour markers
        ...List.generate(
          12,
          (index) {
            final hour = index == 0 ? 12 : index;
            final angle = (index * 30) * math.pi / 180;
            final radius = 270 / 2;
            final x = radius * math.sin(angle);
            final y = -radius * math.cos(angle);

            return Positioned(
              left: size / 2 - 40 + x,
              top: size / 2 - 40 + y,
              child: GestureDetector(
                onTap: () {
                  controller.setHour(index);
                  controller.toggleHourMinuteSelection();
                },
                child: Obx(
                  () => Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.displayHour == hour
                          ? primaryColor
                          : Colors.transparent,
                    ),
                    child: Text(
                      hour.toString(),
                      style: TextStyle(
                        color: controller.displayHour == hour
                            ? Colors.white
                            : ThemeService.isDark.value
                                ? Colors.white
                                : textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Draggable hour hand
        DraggableClockHand(
          size: size - 40,
          initialAngle: _getHourAngle(),
          primaryColor: primaryColor,
          onAngleChanged: (angle) {
            // Convert angle to hour (0-11)
            final hourDouble = (angle / (math.pi * 2)) * 12;
            final hour = ((hourDouble + 0.5).floor()) % 12;
            controller.setHour(hour);
          },
          onDragEnd: () {
            // Optionally switch to minute selection when hour drag ends
            controller.toggleHourMinuteSelection();
          },
        ),
      ],
    );
  }

  double _getHourAngle() {
    final hour = controller.displayHour;
    return ((hour % 12) / 12) * math.pi * 2;
  }

  Widget _buildMinuteSelection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Minute markers
        ...List.generate(
          12,
          (index) {
            final minute = index * 5;
            final angle = (index * 30) * math.pi / 180;
            final radius = 270 / 2;
            final x = radius * math.sin(angle);
            final y = -radius * math.cos(angle);
            // final hour = index == 0 ? 12 : index;
            // final angle = (index * 30) * math.pi / 180;
            // final radius = 270 / 2;
            // final x = radius * math.sin(angle);
            // final y = -radius * math.cos(angle);

            return Positioned(
              left: size / 2 - 40 + x,
              top: size / 2 - 40 + y,
              child: GestureDetector(
                onTap: () {
                  controller.setMinute(minute);
                },
                child: Obx(
                  () => Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.selectEndTime.value.minute == minute
                          ? primaryColor
                          : Colors.transparent,
                    ),
                    child: Text(
                      minute.toString(),
                      style: TextStyle(
                        color:
                            controller.selectEndTime.value.minute == minute
                                ? Colors.black
                                : ThemeService.isDark.value
                                    ? Colors.white
                                    : textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Draggable minute hand
        DraggableClockHand(
          size: size - 40,
          initialAngle: _getMinuteAngle(),
          primaryColor: primaryColor,
          onAngleChanged: (angle) {
            // Convert angle to minute (0-59)
            final minuteDouble = (angle / (math.pi * 2)) * 60;
            final minute = ((minuteDouble + 0.5).floor()) % 60;
            controller.setMinute(minute);
          },
        ),
      ],
    );
  }

  double _getMinuteAngle() {
    final minute = controller.selectEndTime.value.minute;
    return (minute / 60) * math.pi * 2;
  }

  Widget _buildFooter() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // AM/PM toggle
          Obx(
            () => Row(
              children: [
                _buildToggleButton(
                  text: 'morning'.tr,
                  isSelected: controller.isAM.value,
                  onTap: () {
                    if (!controller.isAM.value) {
                      controller.toggleAMPM();
                    }
                  },
                ),
                SizedBox(width: 5.w),
                _buildToggleButton(
                  text: 'evening'.tr,
                  isSelected: !controller.isAM.value,
                  onTap: () {
                    if (controller.isAM.value) {
                      controller.toggleAMPM();
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Hour/Minute toggle
          Obx(() => Row(
                children: [
                  _buildToggleButton(
                    text: 'hour'.tr,
                    isSelected: controller.isHourSelection.value,
                    onTap: () {
                      if (!controller.isHourSelection.value) {
                        controller.toggleHourMinuteSelection();
                      }
                    },
                  ),
                  SizedBox(width: 5.w),
                  _buildToggleButton(
                    text: 'minute'.tr,
                    isSelected: !controller.isHourSelection.value,
                    onTap: () {
                      if (controller.isHourSelection.value) {
                        controller.toggleHourMinuteSelection();
                      }
                    },
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class DraggableClockHand extends StatefulWidget {
  final double size;
  final double initialAngle;
  final Color primaryColor;
  final Function(double) onAngleChanged;
  final VoidCallback? onDragEnd;

  const DraggableClockHand({
    Key? key,
    required this.size,
    required this.initialAngle,
    required this.primaryColor,
    required this.onAngleChanged,
    this.onDragEnd,
  }) : super(key: key);

  @override
  DraggableClockHandState createState() => DraggableClockHandState();
}

class DraggableClockHandState extends State<DraggableClockHand> {
  late double _angle;

  @override
  void initState() {
    super.initState();
    _angle = widget.initialAngle;
  }

  @override
  void didUpdateWidget(DraggableClockHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAngle != widget.initialAngle) {
      _angle = widget.initialAngle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: HandPainter(
            angle: _angle,
            handLength: widget.size / 2 - 35,
            handColor: widget.primaryColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    _updateAngleFromPosition(details.localPosition, center);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    _updateAngleFromPosition(details.localPosition, center);
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.onDragEnd != null) {
      widget.onDragEnd!();
    }
  }

  void _updateAngleFromPosition(Offset position, Offset center) {
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;

    // Calculate angle in radians
    final newAngle = math.atan2(dx, -dy);

    // Normalize angle to be between 0 and 2π
    final normalizedAngle = (newAngle < 0) ? newAngle + math.pi * 2 : newAngle;

    setState(() {
      _angle = normalizedAngle;
    });

    widget.onAngleChanged(normalizedAngle);
  }
}

class HandPainter extends CustomPainter {
  final double angle;
  final double handLength;
  final Color handColor;
  final double strokeWidth;

  HandPainter({
    required this.angle,
    required this.handLength,
    required this.handColor,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final endPoint = Offset(
      center.dx + handLength * math.sin(angle),
      center.dy - handLength * math.cos(angle),
    );

    final paint = Paint()
      ..color = handColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, endPoint, paint);

    // Draw a circle at the end of the hand
    final circlePaint = Paint()
      ..color = handColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(endPoint, 5, circlePaint);
  }

  @override
  bool shouldRepaint(HandPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.handLength != handLength ||
        oldDelegate.handColor != handColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// دالة مساعدة لعرض منتقي الوقت الدائري
// Future<TimeOfDay?> showCircularTimePicker({
//   required BuildContext context,
//   TimeOfDay? initialTime,
//   Color primaryColor = Colors.indigo,
// }) async {
//   final controller = CircularTimePickerController();
//   if (initialTime != null) {
//     controller.selectedTime.value = initialTime;
//     controller.isAM.value = initialTime.hour < 12;
//   }

//   return await showDialog<TimeOfDay>(
//     context: context,
//     builder: (context) => Dialog(
//       backgroundColor: Colors.transparent,
//       child: CircularTimePicker(
//         controller: controller,
//         primaryColor: primaryColor,
//         onDone: () {
//           Navigator.of(context).pop(controller.selectedTime.value);
//         },
//       ),
//     ),
//   );
// }
