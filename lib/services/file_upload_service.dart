import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class FileUploadService {
  static final ImagePicker _picker = ImagePicker();
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Pick an image from gallery or camera that works on both web and mobile
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      print('*** DEBUG: Error picking image: $e');
      return null;
    }
  }

  /// Upload an image file to Supabase storage that works on both web and mobile
  static Future<String?> uploadImage(XFile image) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      
      Uint8List fileBytes;
      
      if (kIsWeb) {
        // Web platform
        fileBytes = await image.readAsBytes();
      } else {
        // Mobile platform
        final file = File(image.path);
        fileBytes = await file.readAsBytes();
      }

      // Determine MIME type based on file extension
      final extension = path.extension(image.path).toLowerCase();
      String mimeType;
      
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          mimeType = 'image/jpeg';
          break;
        case '.png':
          mimeType = 'image/png';
          break;
        case '.gif':
          mimeType = 'image/gif';
          break;
        case '.webp':
          mimeType = 'image/webp';
          break;
        default:
          // For web platforms, try to detect from file name or default to JPEG
          if (kIsWeb) {
            final fileName = path.basename(image.path).toLowerCase();
            if (fileName.contains('png')) {
              mimeType = 'image/png';
            } else if (fileName.contains('gif')) {
              mimeType = 'image/gif';
            } else if (fileName.contains('webp')) {
              mimeType = 'image/webp';
            } else {
              // Default to JPEG for web
              mimeType = 'image/jpeg';
            }
          } else {
            // Default to JPEG for mobile
            mimeType = 'image/jpeg';
          }
          break;
      }
      
      print('*** DEBUG: Uploading with MIME type: $mimeType, extension: $extension');

      // Upload to avatars bucket (now that policies are set up)
      await _supabase.storage.from('avatars').uploadBinary(
        fileName, 
        fileBytes,
        fileOptions: FileOptions(contentType: mimeType),
      );

      // Get public URL from avatars bucket
      final urlResponse = _supabase.storage.from('avatars').getPublicUrl(fileName);
      print('*** DEBUG: Image uploaded successfully to avatars bucket: $urlResponse');
      return urlResponse;
    } catch (e) {
      print('*** DEBUG: Error uploading image: $e');
      return null;
    }
  }

  /// Delete an image from Supabase storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        await _supabase.storage.from('avatars').remove([fileName]);
        print('*** DEBUG: Image deleted successfully from avatars bucket: $fileName');
        print('*** DEBUG: Image deleted successfully: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      print('*** DEBUG: Error deleting image: $e');
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int> getFileSize(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return bytes.length;
    } catch (e) {
      print('*** DEBUG: Error getting file size: $e');
      return 0;
    }
  }

  /// Validate image file (size and type)
  static Future<bool> validateImage(XFile file) async {
    try {
      final size = await getFileSize(file);
      final maxSize = 5 * 1024 * 1024; // 5MB limit
      
      print('*** DEBUG: File size: ${size} bytes, max allowed: ${maxSize} bytes');
      
      if (size > maxSize) {
        print('*** DEBUG: File too large: ${size} bytes');
        return false;
      }

      // For web platforms, be very permissive - just check file size
      if (kIsWeb) {
        print('*** DEBUG: Web platform - only checking file size, accepting file');
        return true;
      }

      // For mobile platforms, check file extension
      String fileName = path.basename(file.path).toLowerCase();
      String extension = path.extension(file.path).toLowerCase();
      
      print('*** DEBUG: File name: $fileName, extension: $extension');
      print('*** DEBUG: Is web platform: $kIsWeb');
      
      // For mobile platforms, check file extension
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      bool hasValidExtension = allowedExtensions.contains(extension);
      
      print('*** DEBUG: Has valid extension: $hasValidExtension');
      
      // If no extension or invalid extension, check if the filename contains image-related keywords
      if (!hasValidExtension) {
        final imageKeywords = ['image', 'photo', 'picture', 'img', 'pic'];
        hasValidExtension = imageKeywords.any((keyword) => fileName.contains(keyword));
        print('*** DEBUG: Checked image keywords, result: $hasValidExtension');
      }
      
      if (!hasValidExtension) {
        print('*** DEBUG: Invalid file type: $extension from file: $fileName');
        return false;
      }

      print('*** DEBUG: File validation passed');
      return true;
    } catch (e) {
      print('*** DEBUG: Error validating image: $e');
      return false;
    }
  }
}
