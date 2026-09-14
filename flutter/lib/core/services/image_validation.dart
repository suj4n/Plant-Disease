import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show decodeImageFromList;

/// Client-side checks run before an upload.
///
/// This is a fast-fail convenience, not a security boundary — the backend
/// revalidates everything. Classification always happens server-side.
class ImageValidation {
  const ImageValidation.valid()
      : isValid = true,
        message = null;

  const ImageValidation.invalid(this.message) : isValid = false;

  final bool isValid;

  /// Ready to display. Null when valid.
  final String? message;
}

/// Must match the server limit, so we never upload something it will reject.
const int maxUploadBytes = 10 * 1024 * 1024;
const int minImageDimension = 64;

const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'bmp'};

Future<ImageValidation> validateImageFile(File file) async {
  if (!await file.exists()) {
    return const ImageValidation.invalid(
      "That photo is no longer available. Please pick or take another one.",
    );
  }

  final extension = file.path.split('.').last.toLowerCase();
  if (!allowedExtensions.contains(extension)) {
    return const ImageValidation.invalid(
      'That file type is not supported. Use a JPG, PNG or WebP photo.',
    );
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    return const ImageValidation.invalid(
      'That photo appears to be empty. Please try another one.',
    );
  }
  if (bytes.length > maxUploadBytes) {
    return const ImageValidation.invalid(
      'That photo is too large. Try taking a new one with the camera.',
    );
  }

  // Decoding is the only real proof the bytes are an image.
  final ui.Image decoded;
  try {
    decoded = await decodeImageFromList(bytes);
  } catch (_) {
    return const ImageValidation.invalid(
      "We couldn't read that photo. Please try another one.",
    );
  }

  final width = decoded.width;
  final height = decoded.height;
  decoded.dispose();

  if (width < minImageDimension || height < minImageDimension) {
    return const ImageValidation.invalid(
      'That photo is too small to analyse. Move closer and take a clearer one.',
    );
  }

  return const ImageValidation.valid();
}
