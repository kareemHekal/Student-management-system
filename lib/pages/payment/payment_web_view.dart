import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EasyKashWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String redirectUrl; // الرابط اللي إحنا حددناه Studenizer

  const EasyKashWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.redirectUrl,
  });

  @override
  State<EasyKashWebViewPage> createState() => _EasyKashWebViewPageState();
}

class _EasyKashWebViewPageState extends State<EasyKashWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // أول ما نلاقي الصفحة اتحولت للرابط بتاعنا Studenizer
            // معناه إن العميل خلص (سواء نجاح أو فشل)
            if (url.contains(widget.redirectUrl)) {
              Navigator.pop(
                  context, true); // ارجع للصفحة اللي قبلها وقولها "خلصنا"
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الدفع الآمن - Studenizer")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
