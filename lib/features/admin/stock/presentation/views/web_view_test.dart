import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/helpers/custom_app_bar.dart';

class EditProductWebView extends StatefulWidget {
  const EditProductWebView({Key? key}) : super(key: key);

  @override
  State<EditProductWebView> createState() => _EditProductWebViewState();
}

class _EditProductWebViewState extends State<EditProductWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => debugPrint("➡️ Loading: $url"),
          onPageFinished: (url) => debugPrint("✅ Loaded: $url"),
        ),
      )
      ..loadRequest(
        Uri.parse("https://drbike.mj-sall.com/"),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
          title: '',
          //  'addProduct'
          action: false),
      body: WebViewWidget(controller: _controller),
    );
  }
}
