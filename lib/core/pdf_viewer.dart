import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> _downloadAndShare(Uri uri, BuildContext context) async {
  try {
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download file')));
      return;
    }
    final bytes = res.bodyBytes;
    final tmpDir = await getTemporaryDirectory();
    final filename = p.basename(uri.path).isNotEmpty ? p.basename(uri.path) : 'document.pdf';
    final file = File(p.join(tmpDir.path, filename));
    await file.writeAsBytes(bytes);
    await Share.shareFiles([file.path], text: uri.toString());
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sharing file')));
  }
}

void viewPdfInline(String title, String url, BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.98,
          height: MediaQuery.of(context).size.height * 0.98,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      // If the provided url is an http(s) URL, download & share it; otherwise share the url string
                      final uri = Uri.tryParse(url);
                      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
                        await _downloadAndShare(uri, context);
                      } else {
                        await Share.share(url);
                      }
                    },
                    icon: const Icon(Icons.share),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Expanded(
                child: PdfDocumentViewBuilder.uri(
                  Uri.parse(url),
                  preferRangeAccess: true,
                  useProgressiveLoading: true,
                  builder: (context, document) {
                    // While pdfrx is fetching the document, it may provide null.
                    // Show a loading indicator while document == null.
                    if (document == null) {
                      return const Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(strokeWidth: 4.0),
                        ),
                      );
                    }

                    // If document exists but has no pages, show an error message.
                    if (document.pages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                              SizedBox(height: 8),
                              Text(
                                'Unable to load document.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return PdfDialogViewer(
                      document: document,
                      title: title,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


class PdfDialogViewer extends StatefulWidget {
  final PdfDocument document;
  final String title;

  const PdfDialogViewer({Key? key, required this.document, required this.title}) : super(key: key);

  @override
  State<PdfDialogViewer> createState() => _PdfDialogViewerState();
}

class _PdfDialogViewerState extends State<PdfDialogViewer> {
  late final PageController _pageController;
  late final int _totalPages;
  int _currentPage = 0;
  final TransformationController _transformationController = TransformationController();
  final double _minScale = 1.0;
  final double _maxScale = 4.0;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
  _totalPages = widget.document.pages.length;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _totalPages) return;
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _setScale(double scale) {
    final clamped = scale.clamp(_minScale, _maxScale);
    _currentScale = clamped;
    _transformationController.value = Matrix4.identity()..scale(clamped);
    setState(() {});
  }

  void _zoomIn() => _setScale(_currentScale * 1.25);
  void _zoomOut() => _setScale(_currentScale / 1.25);
  void _resetZoom() => _setScale(1.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalPages,
            onPageChanged: (index) {
              // reset zoom when changing pages
              _resetZoom();
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onDoubleTap: () {
                          if (_currentScale <= 1.0) {
                            _setScale(2.0);
                          } else {
                            _resetZoom();
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          panEnabled: true,
                          scaleEnabled: true,
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: _minScale,
                          maxScale: _maxScale,
                          child: PdfPageView(
                            document: widget.document,
                            pageNumber: index + 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Controls: Previous / Page indicator / Next
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
                onPressed: _currentPage > 0 ? () => _goTo(_currentPage - 1) : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                tooltip: 'Zoom out',
                onPressed: _currentScale > _minScale ? _zoomOut : null,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset zoom',
                onPressed: _currentScale != 1.0 ? _resetZoom : null,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                tooltip: 'Zoom in',
                onPressed: _currentScale < _maxScale ? _zoomIn : null,
              ),
              const SizedBox(width: 12),
              Text('${_currentPage + 1} / $_totalPages'),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
                onPressed: _currentPage < _totalPages - 1 ? () => _goTo(_currentPage + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}