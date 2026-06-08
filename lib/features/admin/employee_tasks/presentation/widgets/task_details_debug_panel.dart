import 'package:flutter/material.dart';

/// On-screen debug log (disabled — console logs remain via [TaskDetailsDebug]).
class TaskDetailsDebugPanel extends StatelessWidget {
  const TaskDetailsDebugPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
