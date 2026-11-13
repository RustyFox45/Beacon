import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/theme.dart';

class WebViewerScreen extends StatefulWidget {
  final String url;
  final String? title;

  const WebViewerScreen({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<WebViewerScreen> createState() => _WebViewerScreenState();
}

class _WebViewerScreenState extends State<WebViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      );

    try {
      _controller.loadRequest(Uri.parse(widget.url));
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      _controller.loadRequest(Uri.parse(widget.url));
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title != null
            ? Text(
                widget.title!,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              )
            : null,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: AppIcons.close(),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _hasError ? _buildError() : _buildWebView(),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.black38),
            const SizedBox(height: 16),
            const Text(
              'Unable to load page',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.url,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
