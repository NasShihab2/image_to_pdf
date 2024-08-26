import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_to_pdf/view_pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageToPdfPage extends StatefulWidget {
  const ImageToPdfPage({super.key});

  @override
  ImageToPdfPageState createState() => ImageToPdfPageState();
}

class ImageToPdfPageState extends State<ImageToPdfPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _images = [];
  final file = File("/storage/emulated/0/Download/images.pdf");
  bool _isLoading = false; // Track loading state for image picking
  bool _isGenerating = false; // Track loading state for PDF generation

  Future<void> _pickImages() async {
    setState(() {
      _isLoading = true; // Start loading for image picking
    });

    final List<XFile>? selectedImages = await _picker.pickMultiImage(imageQuality: 80);

    setState(() {
      _isLoading = false; // Stop loading for image picking
      if (selectedImages != null && selectedImages.isNotEmpty && selectedImages.length <= 3) {
        _images = selectedImages;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select between 1 and 3 images.")),
        );
      }
    });
  }

  Future<Uint8List> _compressImage(File file) async {
    final imageBytes = await file.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    img.Image compressedImage = img.copyResize(originalImage!, width: 800); // Resize for compression

    return Uint8List.fromList(img.encodeJpg(compressedImage, quality: 60)); // Compress the image further
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true; // Start loading for PDF generation
    });

    final pdf = pw.Document();

    for (var image in _images!) {
      final imageFile = File(image.path);
      final compressedImageBytes = await _compressImage(imageFile);
      final pdfImage = pw.MemoryImage(compressedImageBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(pdfImage));
          },
        ),
      );
    }

    // Get the path to the Downloads folder
    final downloadsDirectory = Directory(path.join((await getDownloadsDirectory())!.path));
    if (!downloadsDirectory.existsSync()) {
      downloadsDirectory.createSync(recursive: true);
    }

    Uint8List pdfData = await pdf.save();
    if (pdfData.lengthInBytes <= 1024 * 1024) {
      await file.writeAsBytes(pdfData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF saved in Downloads at ${file.path}")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF exceeds 1 MB. Try reducing image size or quality.")),
      );
    }

    setState(() {
      _isGenerating = false; // Stop loading for PDF generation
    });
  }

  Future<Directory?> getDownloadsDirectory() async {
    // Returns the Downloads directory for both Android and iOS.
    return await getExternalStorageDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image to PDF")),
      body: Center(
        child: _isLoading || _isGenerating // Show loading indicator if either is loading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _pickImages,
                    child: const Text("Pick Images"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _images != null && _images!.isNotEmpty ? _generatePdf : null,
                    child: const Text("Generate PDF"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (file.existsSync()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewerPage(pdfPath: file.path),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("PDF file not found.")),
                        );
                      }
                    },
                    child: const Text("Open PDF"),
                  ),
                ],
              ),
      ),
    );
  }
}
