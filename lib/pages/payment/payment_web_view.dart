import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
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
      appBar: AppBar(
          backgroundColor: AppColors.primaryMain,
          toolbarHeight: 70,
          centerTitle: true,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.white,
              )),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25))),
          title: const Text(
              style: TextStyle(color: AppColors.white),
              "الدفع الآمن  Studenizer")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
