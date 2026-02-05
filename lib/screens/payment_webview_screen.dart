import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String checkoutUrl;

  const PaymentWebViewScreen({super.key, required this.checkoutUrl});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });

            // Check if payment was completed (redirected to return_url)
            // Important: check if it starts with the return URL, not just contains it
            if (url.startsWith('https://yourapp.com/payment/result') ||
                url.startsWith('http://yourapp.com/payment/result')) {
              // Payment completed, close WebView
              Navigator.of(context).pop(true);
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Оплата подписки', style: AppTextStyles.h4),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
