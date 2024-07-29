import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:async';
import 'dart:io';
import '../services/image_processing_service.dart';
import '../services/database_service.dart';
import '../models/document_model.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCaptured = false;
  String? _imagePath;
  final ImageProcessingService _imageProcessingService =
      ImageProcessingService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      XFile picture = await _controller!.takePicture();
      await picture.saveTo(path);

      setState(() {
        _isCaptured = true;
        _imagePath = path;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _processImage() async {
    if (_imagePath != null) {
      File imageFile = File(_imagePath!);
      File enhancedImage =
          await _imageProcessingService.enhanceImage(imageFile);
      File straightenedImage =
          await _imageProcessingService.straightenDocument(enhancedImage);
      setState(() {
        _imagePath = straightenedImage.path;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_imagePath != null) {
      String title = _titleController.text.isNotEmpty
          ? _titleController.text
          : "Scanned Document ${DateTime.now().toString()}";
      String category = _categoryController.text.isNotEmpty
          ? _categoryController.text
          : "Uncategorized";

      Document newDocument = Document(
        title: title,
        filePath: _imagePath!,
        dateCreated: DateTime.now(),
        category: category,
      );

      await _databaseService.insertDocument(newDocument);
      Navigator.pop(
          context, true); // Return true to indicate a new document was added
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Document'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                _isCaptured
                    ? Image.file(File(_imagePath!))
                    : CameraPreview(_controller!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isCaptured) ...[
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Document Title',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _categoryController,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              child: Icon(_isCaptured
                                  ? Icons.refresh
                                  : Icons.camera_alt),
                              onPressed: _isCaptured
                                  ? () {
                                      setState(() {
                                        _isCaptured = false;
                                        _imagePath = null;
                                        _titleController.clear();
                                        _categoryController.clear();
                                      });
                                    }
                                  : _takePicture,
                            ),
                            if (_isCaptured)
                              ElevatedButton(
                                child: Text('Process'),
                                onPressed: _processImage,
                              ),
                            if (_isCaptured)
                              ElevatedButton(
                                child: Text('Save'),
                                onPressed: _saveDocument,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
