import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:taskswap/models/avatar_model.dart';

class AvatarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a custom avatar image
  Future<String?> uploadCustomAvatar(String userId, File imageFile) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      final storageRef = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      // Upload the file
      await storageRef.putFile(imageFile);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update user document with the new avatar URL and mark it as custom
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
        'avatarType': 'custom',
      });

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading custom avatar: $e');
      return null;
    }
  }

  // Select a predefined avatar
  Future<bool> selectPredefinedAvatar(String userId, String avatarId) async {
    try {
      // Find the avatar by ID
      final avatar = AvatarData.findAvatarById(avatarId);
      if (avatar == null) {
        debugPrint('Avatar not found with ID: $avatarId');
        return false;
      }

      // First, try to download the image to verify it exists
      final http.Response response = await http.get(Uri.parse(avatar.url));
      if (response.statusCode != 200) {
        debugPrint('Error downloading avatar image: ${response.statusCode}');
        return false;
      }

      // Use the direct URL from Imgur instead of trying to cache in Firebase Storage
      // Update user document with the predefined avatar URL
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': avatar.url,
        'avatarType': 'predefined',
        'avatarId': avatarId,
      });

      return true;
    } catch (e) {
      debugPrint('Error selecting predefined avatar: $e');
      return false;
    }
  }

  // Get all predefined avatars
  List<AvatarCategory> getPredefinedAvatarCategories() {
    return AvatarData.categories;
  }

  // Get all avatars as a flat list
  List<PredefinedAvatar> getAllPredefinedAvatars() {
    return AvatarData.allAvatars;
  }
}
