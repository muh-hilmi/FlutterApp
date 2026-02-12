import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageOptionsSelector extends StatelessWidget {
  final Function(ImageSource?) onOptionSelected;

  const ImageOptionsSelector({super.key, required this.onOptionSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildImageOption('Ambil Foto 📸', ImageSource.camera),
        const SizedBox(height: 8),
        _buildImageOption('Pilih dari Galeri 🖼️', ImageSource.gallery),
        const SizedBox(height: 8),
        _buildImageOption('Skip aja →', null),
      ],
    );
  }

  Widget _buildImageOption(String label, ImageSource? source) {
    return GestureDetector(
      onTap: () => onOptionSelected(source),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: source == null ? Colors.grey[300] : const Color(0xFFBBC863),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: source == null ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: source == null ? Colors.black87 : Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
