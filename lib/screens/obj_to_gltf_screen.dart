import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/obj_to_gltf_converter.dart';

class ObjToGltfScreen extends StatefulWidget {
  const ObjToGltfScreen({super.key});

  @override
  State<ObjToGltfScreen> createState() => _ObjToGltfScreenState();
}

class _ObjToGltfScreenState extends State<ObjToGltfScreen> {
  final TextEditingController _inputPathController = TextEditingController();
  final TextEditingController _outputPathController = TextEditingController();
  bool _isConverting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _inputPathController.dispose();
    _outputPathController.dispose();
    super.dispose();
  }

  Future<void> _convertFile() async {
    final inputPath = _inputPathController.text.trim();
    
    if (inputPath.isEmpty) {
      _showStatus('Please enter an input file path', isSuccess: false);
      return;
    }

    // Check if input file exists
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      _showStatus('Input file does not exist: $inputPath', isSuccess: false);
      return;
    }

    setState(() {
      _isConverting = true;
      _statusMessage = 'Converting...';
      _isSuccess = false;
    });

    try {
      final outputPath = _outputPathController.text.trim().isEmpty
          ? null
          : _outputPathController.text.trim();

      final result = await ObjToGltfConverter.convert(
        inputPath: inputPath,
        outputPath: outputPath,
      );

      _showStatus('Success! Converted to: $result', isSuccess: true);
      
      // Update output path controller with the result
      _outputPathController.text = result;
    } catch (e) {
      _showStatus('Error: ${e.toString()}', isSuccess: false);
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  void _showStatus(String message, {required bool isSuccess}) {
    setState(() {
      _statusMessage = message;
      _isSuccess = isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input file path field
            TextField(
              controller: _inputPathController,
              decoration: const InputDecoration(
                labelText: 'Input OBJ File Path',
                hintText: 'e.g., assets/1/model.obj',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.input),
              ),
              enabled: !_isConverting,
            ),
            const SizedBox(height: 16),

            // Output file path field (optional)
            TextField(
              controller: _outputPathController,
              decoration: const InputDecoration(
                labelText: 'Output glTF File Path (Optional)',
                hintText: 'Leave empty for auto-generated path',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.output),
              ),
              enabled: !_isConverting,
            ),
            const SizedBox(height: 24),

            // Convert button
            ElevatedButton.icon(
              onPressed: _isConverting ? null : _convertFile,
              icon: _isConverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.transform),
              label: Text(_isConverting ? 'Converting...' : 'Convert to glTF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Status message
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Platform info
            if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Note: OBJ to glTF conversion is only supported on desktop platforms (macOS, Windows, Linux)',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
              ),
            ),
          ],
        ),
    );
  }
}

