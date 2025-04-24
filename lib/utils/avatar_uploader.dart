import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// This is a utility class to upload sample avatars to Firebase Storage.
/// It's meant to be used only during development to set up the initial avatars.
class AvatarUploader {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Sample avatar URLs from public domain sources
  final Map<String, List<String>> _sampleAvatars = {
    'cartoon': [
      'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
      'https://cdn-icons-png.flaticon.com/512/4140/4140047.png',
      'https://cdn-icons-png.flaticon.com/512/4140/4140051.png',
      'https://cdn-icons-png.flaticon.com/512/4140/4140037.png',
    ],
    'superhero': [
      'https://cdn-icons-png.flaticon.com/512/1674/1674291.png',
      'https://cdn-icons-png.flaticon.com/512/1674/1674352.png',
      'https://cdn-icons-png.flaticon.com/512/1674/1674293.png',
      'https://cdn-icons-png.flaticon.com/512/1674/1674292.png',
    ],
    'sports': [
      'https://cdn-icons-png.flaticon.com/512/3048/3048122.png',
      'https://cdn-icons-png.flaticon.com/512/3048/3048127.png',
      'https://cdn-icons-png.flaticon.com/512/3048/3048189.png',
      'https://cdn-icons-png.flaticon.com/512/3048/3048139.png',
    ],
    'animal': [
      'https://cdn-icons-png.flaticon.com/512/3069/3069172.png',
      'https://cdn-icons-png.flaticon.com/512/3069/3069170.png',
      'https://cdn-icons-png.flaticon.com/512/3069/3069186.png',
      'https://cdn-icons-png.flaticon.com/512/3069/3069162.png',
    ],
  };
  
  /// Upload all sample avatars to Firebase Storage
  Future<Map<String, List<String>>> uploadSampleAvatars() async {
    final Map<String, List<String>> uploadedUrls = {};
    
    try {
      for (final category in _sampleAvatars.keys) {
        uploadedUrls[category] = [];
        
        for (int i = 0; i < _sampleAvatars[category]!.length; i++) {
          final url = _sampleAvatars[category]![i];
          final id = '${category}_${i + 1}';
          
          // Download the image
          final imageBytes = await _downloadImage(url);
          if (imageBytes == null) continue;
          
          // Upload to Firebase Storage
          final downloadUrl = await _uploadImageBytes(imageBytes, id, category);
          if (downloadUrl != null) {
            uploadedUrls[category]!.add(downloadUrl);
            debugPrint('Uploaded $id: $downloadUrl');
          }
        }
      }
      
      return uploadedUrls;
    } catch (e) {
      debugPrint('Error uploading sample avatars: $e');
      return uploadedUrls;
    }
  }
  
  /// Download image from URL
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }
  
  /// Upload image bytes to Firebase Storage
  Future<String?> _uploadImageBytes(Uint8List bytes, String id, String category) async {
    try {
      final ref = _storage.ref().child('predefined_avatars').child('$id.png');
      
      // Upload the file
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );
      
      // Get download URL
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}
