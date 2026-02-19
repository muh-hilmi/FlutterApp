import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/community.dart';
import '../../../domain/entities/community_category.dart';
import '../../bloc/communities/communities_bloc.dart';
import '../../bloc/communities/communities_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CommunityCategory _selectedCategory = CommunityCategory.social;
  String _selectedLocation = 'Jakarta';
  String _selectedIcon = '🎉';

  final List<String> _locations = [
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Yogyakarta',
    'Boyolali',
    'Semarang',
    'Bali',
  ];

  final List<String> _icons = [
    '💻',
    '⚽',
    '📸',
    '🍜',
    '💼',
    '🏔️',
    '☕',
    '📚',
    '🎵',
    '🎮',
    '🏃',
    '🎨',
    '🍕',
    '✈️',
    '🎬',
    '📱',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createCommunity() {
    if (_formKey.currentState!.validate()) {
      final community = Community(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        location: _selectedLocation,
        icon: _selectedIcon,
        memberCount: 1,
        isVerified: false,
        createdAt: DateTime.now(),
      );

      context.read<CommunitiesBloc>().add(CreateCommunityRequested(community));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Community "${community.name}" berhasil dibuat!'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textEmphasis),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bikin Community',
          style: AppTextStyles.h3.copyWith(color: AppColors.textEmphasis),
        ),
        actions: [
          TextButton(
            onPressed: _createCommunity,
            child: Text(
              'Buat',
              style: AppTextStyles.bodyLargeBold.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Icon selector
            Text(
              'Icon Community',
              style: AppTextStyles.bodyLargeBold.copyWith(
                color: AppColors.textEmphasis,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withValues(alpha: 0.2)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            Text(
              'Nama Community',
              style: AppTextStyles.bodyLargeBold.copyWith(
                color: AppColors.textEmphasis,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Contoh: Jakarta Developers',
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama community harus diisi';
                }
                if (value.trim().length < 3) {
                  return 'Nama community minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Description field
            Text(
              'Deskripsi',
              style: AppTextStyles.bodyLargeBold.copyWith(
                color: AppColors.textEmphasis,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ceritain tentang community kamu...',
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi harus diisi';
                }
                if (value.trim().length < 10) {
                  return 'Deskripsi minimal 10 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Category selector
            Text(
              'Kategori',
              style: AppTextStyles.bodyLargeBold.copyWith(
                color: AppColors.textEmphasis,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CommunityCategory>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: CommunityCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text('${category.emoji} ${category.displayName}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location selector
            Text(
              'Lokasi',
              style: AppTextStyles.bodyLargeBold.copyWith(
                color: AppColors.textEmphasis,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLocation = value;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _createCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Buat Community',
                  style: AppTextStyles.bodyLargeBold.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info text
            Text(
              'Dengan membuat community, kamu setuju untuk mematuhi aturan dan pedoman komunitas kami.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
