import 'dart:io';
import 'package:path/path.dart' as path;

/// Executes the objToGltf.js script to convert OBJ files to glTF
/// 
/// Note: This only works on desktop platforms (macOS, Windows, Linux)
/// as it requires Node.js to be installed.
class ObjToGltfConverter {
  /// Converts an OBJ file to glTF format
  /// 
  /// [inputPath] - Path to the input OBJ file
  /// [outputPath] - Optional output path. If not provided, will be auto-generated
  /// 
  /// Returns a Future with the output file path on success
  static Future<String> convert({
    required String inputPath,
    String? outputPath,
  }) async {
    // Check if running on a supported platform
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      throw UnsupportedError(
        'OBJ to glTF conversion is only supported on desktop platforms (macOS, Windows, Linux)',
      );
    }

    // Get the script path relative to the project root
    final scriptPath = path.join(
      Directory.current.path,
      'objToGltf.js',
    );

    // Check if script exists
    final scriptFile = File(scriptPath);
    if (!await scriptFile.exists()) {
      throw FileSystemException(
        'objToGltf.js script not found',
        scriptPath,
      );
    }

    // Check if Node.js is available
    try {
      final nodeResult = await Process.run('node', ['--version']);
      if (nodeResult.exitCode != 0) {
        throw Exception('Node.js is not installed or not in PATH');
      }
    } catch (e) {
      throw Exception('Node.js is not installed or not in PATH: $e');
    }

    // Build command arguments
    final args = [scriptPath, inputPath];
    if (outputPath != null && outputPath.isNotEmpty) {
      args.add(outputPath);
    }

    // Execute the script
    final result = await Process.run(
      'node',
      args,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception(
        'Conversion failed: ${result.stderr}\n${result.stdout}',
      );
    }

    // Parse output path from result or use default
    final finalOutputPath = outputPath ??
        path.join(
          path.dirname(inputPath),
          '${path.basenameWithoutExtension(inputPath)}.gltf',
        );

    return finalOutputPath;
  }
}

