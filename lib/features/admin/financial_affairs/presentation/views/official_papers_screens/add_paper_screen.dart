import 'package:flutter/material.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';

class AddPaperScreen extends StatelessWidget {
  const AddPaperScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: 'add_document', action: false),
    );
  }
}
