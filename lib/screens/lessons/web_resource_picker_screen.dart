import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../../theme/theme.dart';

class WebResourcePickerScreen extends StatefulWidget {
  final String initialUrl;

  const WebResourcePickerScreen({
    super.key,
    this.initialUrl = 'https://www.churchofjesuschrist.org/study?lang=eng&platform=web',
  });

  @override
  State<WebResourcePickerScreen> createState() => _WebResourcePickerScreenState();
}

class _WebResourcePickerScreenState extends State<WebResourcePickerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _handleDone() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null) {
        Navigator.pop(context);
        return;
      }

      // Fetch metadata
      final data = await MetadataFetch.extract(currentUrl);
      
      Navigator.pop(context, {
        'url': currentUrl,
        'title': data?.title ?? 'Resource',
        'image': data?.image,
      });
    } catch (e) {
      debugPrint('Error fetching metadata: $e');
      Navigator.pop(context, {
        'url': _currentUrl,
        'title': 'Resource',
        'image': null,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Resource', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: AppIcons.close(),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleDone,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Done'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
        ],
      ),
    );
  }
}
