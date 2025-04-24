import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageOptimizer {
  /// Compresses an image file and returns the compressed file
  ///
  /// [file] - The original image file
  /// [quality] - The quality of the compressed image (0-100)
  /// [maxWidth] - The maximum width of the compressed image
  /// [maxHeight] - The maximum height of the compressed image
  static Future<File?> compressImageFile({
    required File file,
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1920,
  }) async {
    try {
      // Get file extension
      final extension = path.extension(file.path).toLowerCase();

      // Create a temporary directory to store the compressed image
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(tempDir.path, '${const Uuid().v4()}$extension');

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      if (result == null) {
        debugPrint('Image compression failed');
        return null;
      }

      // Convert XFile to File
      return File(result.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Compresses an image from bytes and returns the compressed bytes
  ///
  /// [bytes] - The original image bytes
  /// [quality] - The quality of the compressed image (0-100)
  static Future<Uint8List?> compressImageBytes({
    required Uint8List bytes,
    int quality = 85,
  }) async {
    try {
      // Compress the image bytes
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
      );

      return result;
    } catch (e) {
      debugPrint('Error compressing image bytes: $e');
      return null;
    }
  }

  /// Resizes and compresses a profile image
  ///
  /// [file] - The original image file
  static Future<File?> optimizeProfileImage(File file) async {
    return compressImageFile(
      file: file,
      quality: 80,
      maxWidth: 500,
      maxHeight: 500,
    );
  }

  /// Resizes and compresses an image for the feed
  ///
  /// [file] - The original image file
  static Future<File?> optimizeFeedImage(File file) async {
    return compressImageFile(
      file: file,
      quality: 75,
      maxWidth: 1080,
      maxHeight: 1350,
    );
  }
}
