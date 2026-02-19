import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
          color: source == null ? AppColors.border : AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: source == null ? AppColors.textEmphasis : AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: source == null ? AppColors.textEmphasis : AppColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
