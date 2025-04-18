import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';

class ProfileImagePicker extends StatelessWidget {
  final String? currentImageUrl;
  final File? selectedImage;
  final Function(File) onImageSelected;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    this.selectedImage,
    required this.onImageSelected,
  });

  Future<void> _pickImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        onImageSelected(File(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.surface,
          backgroundImage: selectedImage != null
              ? FileImage(selectedImage!)
              : (currentImageUrl != null
                  ? NetworkImage(currentImageUrl!) as ImageProvider
                  : null),
          child: (selectedImage == null && currentImageUrl == null)
              ? const Icon(Icons.person, size: 50, color: AppColors.primary)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 18,
            child: IconButton(
              icon: const Icon(Icons.camera_alt,
                  size: 18, color: AppColors.surface),
              onPressed: () => _pickImage(context),
            ),
          ),
        ),
      ],
    );
  }
}