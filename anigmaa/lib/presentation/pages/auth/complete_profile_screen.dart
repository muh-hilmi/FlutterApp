import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/datasources/user_remote_datasource.dart';
import '../../../core/services/auth_service.dart';
import '../../../injection_container.dart' as di;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _location;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('complete_profile_screen'),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildBirthDateField(),
                const SizedBox(height: 24),
                _buildGenderField(),
                const SizedBox(height: 24),
                _buildPhoneField(),
                const SizedBox(height: 24),
                _buildLocationField(),
                const SizedBox(height: 40),
                _buildContinueButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lengkapin Profil Lo 📝',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Biar kita bisa rekomendasiin event yang cocok sama lo!',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tanggal Lahir',
              style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Wajib',
                style: AppTextStyles.label.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('dob_field'),
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDate == null
                    ? AppColors.border
                    : AppColors.secondary,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  color: _selectedDate == null
                      ? AppColors.textTertiary
                      : AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null
                      ? 'Pilih tanggal lahir lo'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: _selectedDate == null
                        ? AppColors.textSecondary
                        : AppColors.textEmphasis,
                    fontWeight: _selectedDate == null
                        ? FontWeight.w500
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedGender == null
                  ? AppColors.border
                  : AppColors.secondary,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedGender,
              hint: const Text('Pilih gender'),
              items: _genderOptions.map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nomor HP',
          style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '08123456789',
            prefixIcon: const Icon(Icons.phone_outlined),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lokasi',
              style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Wajib',
                style: AppTextStyles.label.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('location_field'),
          onTap: _isLoadingLocation ? null : _requestLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _location == null
                    ? AppColors.border
                    : AppColors.secondary,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.location_on_outlined,
                        color: _location == null
                            ? AppColors.textTertiary
                            : AppColors.secondary,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _location ?? 'Izinkan akses lokasi',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _location == null
                          ? AppColors.textSecondary
                          : AppColors.textEmphasis,
                      fontWeight: _location == null
                          ? FontWeight.w500
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Buat rekomendasiin event yang deket sama lo',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final isValid = _selectedDate != null && _location != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('submit_button'),
        onPressed: isValid && !_isSubmitting ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.border,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                'Lanjut',
                style: AppTextStyles.bodyLargeBold,
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get location
      final position = await Geolocator.getCurrentPosition();

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationText = [
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _location = locationText.isNotEmpty
              ? locationText
              : 'Location detected';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _location == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update profile data
      final userDataSource = di.sl<UserRemoteDataSource>();
      await userDataSource.updateCurrentUser({
        'date_of_birth': _selectedDate!.toIso8601String(),
        'location': _location,
        if (_selectedGender != null) 'gender': _selectedGender,
        if (_phoneController.text.isNotEmpty) 'phone': _phoneController.text,
      });

      // Refresh local auth state with updated user data
      final authService = di.sl<AuthService>();
      final updatedUser = await userDataSource.getCurrentUser();

      // Get tokens (these are async calls)
      final accessToken = await authService.accessToken;
      final refreshToken = await authService.refreshToken;

      await authService.saveAuthData(
        userId: updatedUser.id,
        email: updatedUser.email ?? '',
        name: updatedUser.name,
        accessToken: accessToken ?? '',
        refreshToken: refreshToken ?? '',
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
