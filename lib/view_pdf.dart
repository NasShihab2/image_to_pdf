import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfPath;

  const PdfViewerPage({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("View PDF")),
      body: PdfView(
        controller: PdfController(
          document: PdfDocument.openFile(pdfPath),
        ),
      ),
    );
  }
}
