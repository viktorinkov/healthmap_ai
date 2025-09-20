import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PollutionVisualizerDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  
  const PollutionVisualizerDialog({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);
  
  @override
  State<PollutionVisualizerDialog> createState() => _PollutionVisualizerDialogState();
}

class _PollutionVisualizerDialogState extends State<PollutionVisualizerDialog> {
  late final WebViewController _controller;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse('http://localhost:5001/pollution_heatmap_interactive.html'),
      );
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Air Quality Visualization',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // WebView content
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PollutionVisualizerButton extends StatelessWidget {
  final double latitude;
  final double longitude;
  
  const PollutionVisualizerButton({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => PollutionVisualizerDialog(
            latitude: latitude,
            longitude: longitude,
          ),
        );
      },
      icon: const Icon(Icons.bubble_chart),
      label: const Text('3D Pollution View'),
    );
  }
}