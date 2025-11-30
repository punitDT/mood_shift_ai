import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  final _isLoading = true.obs;
  final _progress = 0.0.obs;
  
  String get title => Get.arguments?['title'] ?? 'Web Page';
  String get url => Get.arguments?['url'] ?? '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1a0f2e))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            _progress.value = progress / 100;
          },
          onPageStarted: (String url) {
            _isLoading.value = true;
          },
          onPageFinished: (String url) {
            _isLoading.value = false;
          },
          onWebResourceError: (WebResourceError error) {
            _isLoading.value = false;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a0f2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a0f2e),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.h),
          child: Obx(() => _isLoading.value
              ? LinearProgressIndicator(
                  value: _progress.value,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6D5FFD),
                  ),
                )
              : const SizedBox.shrink()),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

