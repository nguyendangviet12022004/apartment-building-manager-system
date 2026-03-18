import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  // Cloudinary configuration - match with backend
  static const String cloudName = 'dnkghao4p';
  static const String uploadPreset = 'apartment_profiles'; // You need to create this in Cloudinary
  static const String apiKey = '399479765913834';
  
  /// Upload image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);
      
      // Add file
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      
      // Add upload preset (unsigned upload)
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'profiles';
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception('Failed to upload image: $responseData');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Delete image from Cloudinary (optional)
  Future<void> deleteImage(String publicId) async {
    // Note: Deletion requires authentication with API secret
    // For now, we'll just skip deletion or handle it on backend
    // Backend should handle cleanup of old images
  }
}
