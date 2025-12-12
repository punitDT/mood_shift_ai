import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/storage_service.dart';
import '../../services/crashlytics_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final CrashlyticsService _crashlytics = Get.find<CrashlyticsService>();

  final appVersion = ''.obs;
  final selectedLanguage = 'English'.obs;
  final selectedVoiceGender = 'Female'.obs;
  final crashReportsEnabled = true.obs;

  final languages = [
    {'code': 'en', 'country': 'US', 'name': 'english'},
    {'code': 'en', 'country': 'GB', 'name': 'english_uk'},
    {'code': 'hi', 'country': 'IN', 'name': 'hindi'},
    {'code': 'es', 'country': 'ES', 'name': 'spanish'},
    {'code': 'zh', 'country': 'CN', 'name': 'chinese'},
    {'code': 'fr', 'country': 'FR', 'name': 'french'},
    {'code': 'de', 'country': 'DE', 'name': 'german'},
    {'code': 'ar', 'country': 'SA', 'name': 'arabic'},
    {'code': 'ja', 'country': 'JP', 'name': 'japanese'},
  ];

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    _loadCurrentLanguage();
    _loadCurrentVoiceGender();
    _loadCrashReportsEnabled();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion.value = packageInfo.version;
  }

  void _loadCurrentLanguage() {
    final currentCode = _storage.getLanguageCode();
    final currentCountry = _storage.getCountryCode();
    final lang = languages.firstWhere(
      (l) => l['code'] == currentCode && l['country'] == currentCountry,
      orElse: () => languages[0],
    );
    selectedLanguage.value = lang['name']!.tr;
  }

  void _loadCurrentVoiceGender() {
    final currentGender = _storage.getVoiceGender();
    selectedVoiceGender.value = currentGender == 'male' ? 'male'.tr : 'female'.tr;
  }

  void _loadCrashReportsEnabled() {
    crashReportsEnabled.value = _crashlytics.getCrashReportsEnabled();
  }

  void showLanguageSelector() {
    final context = Get.context;
    final isTablet = context != null ? ResponsiveUtils.isTablet(context) : false;

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 24.r),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 400 : double.infinity,
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.7,
          ),
          padding: EdgeInsets.all(isTablet ? 24 : 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: isTablet ? 60 : 56.w,
                height: isTablet ? 60 : 56.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF6D5FFD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: Colors.white,
                  size: isTablet ? 32 : 28.sp,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 16.h),
              Text(
                'select_language'.tr,
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 20.h),
              // Language list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  separatorBuilder: (_, __) => SizedBox(height: isTablet ? 8 : 8.h),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final currentCode = _storage.getLanguageCode();
                    final currentCountry = _storage.getCountryCode();
                    final isSelected = lang['code'] == currentCode && lang['country'] == currentCountry;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _changeLanguage(
                            lang['code']!,
                            lang['country']!,
                            lang['name']!,
                          );
                          Get.back();
                        },
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 16.w,
                            vertical: isTablet ? 14 : 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7C4DFF).withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7C4DFF)
                                  : Colors.white.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lang['name']!.tr,
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 16.sp,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF7C4DFF) : Colors.white,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: const Color(0xFF7C4DFF),
                                  size: isTablet ? 24 : 22.sp,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeLanguage(String code, String country, String name) {
    _storage.setLocale(code, country);
    Get.updateLocale(Locale(code, country));
    selectedLanguage.value = name.tr;
  }

  void showVoiceGenderSelector() {
    final context = Get.context;
    final isTablet = context != null ? ResponsiveUtils.isTablet(context) : false;
    final currentGender = _storage.getVoiceGender();

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 24.r),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 380 : double.infinity,
          ),
          padding: EdgeInsets.all(isTablet ? 24 : 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: isTablet ? 60 : 56.w,
                height: isTablet ? 60 : 56.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF6D5FFD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.white,
                  size: isTablet ? 32 : 28.sp,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 16.h),
              Text(
                'voice_gender'.tr,
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 24.h),
              // Voice options
              Row(
                children: [
                  // Male option
                  Expanded(
                    child: _buildVoiceOption(
                      icon: Icons.male_rounded,
                      label: 'male'.tr,
                      color: const Color(0xFF7C4DFF),
                      isSelected: currentGender == 'male',
                      isTablet: isTablet,
                      onTap: () {
                        Get.back();
                        _changeVoiceGender('male');
                      },
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12.w),
                  // Female option
                  Expanded(
                    child: _buildVoiceOption(
                      icon: Icons.female_rounded,
                      label: 'female'.tr,
                      color: const Color(0xFFE91E63),
                      isSelected: currentGender == 'female',
                      isTablet: isTablet,
                      onTap: () {
                        Get.back();
                        _changeVoiceGender('female');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    // Use consistent purple color for selected state
    const selectedColor = Color(0xFF7C4DFF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 16.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12.w,
            vertical: isTablet ? 20 : 20.h,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 16.r),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isTablet ? 56 : 48.w,
                height: isTablet ? 56 : 48.w,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? selectedColor : Colors.white.withOpacity(0.7),
                  size: isTablet ? 32 : 28.sp,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 10.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 15.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedColor : Colors.white,
                ),
              ),
              // Always show the check icon space to keep consistent height
              SizedBox(height: isTablet ? 6 : 4.h),
              Icon(
                Icons.check_circle_rounded,
                color: isSelected ? selectedColor : Colors.transparent,
                size: isTablet ? 20 : 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeVoiceGender(String gender) {
    _storage.setVoiceGender(gender);
    selectedVoiceGender.value = gender.tr;

    // Show snackbar with descriptive message
    final message = gender == 'male'
        ? 'voice_changed_to_male'.tr
        : 'voice_changed_to_female'.tr;

    SnackbarUtils.showCustom(
      title: 'voice_gender'.tr,
      message: message,
      backgroundColor: const Color(0xFF6D5FFD),
      textColor: Colors.white,
      icon: Icons.record_voice_over_rounded,
      duration: const Duration(seconds: 3),
    );
  }

  void openPrivacyPolicy() {
    final url = dotenv.env['PRIVACY_POLICY_URL'] ?? 'https://punitdt.github.io/privacy-policy';
    Get.toNamed(
      AppRoutes.WEBVIEW,
      arguments: {
        'title': 'privacy_policy'.tr,
        'url': url,
      },
    );
  }

  void shareApp() {
    Share.share('share_text'.tr);
  }

  void showAbout() {
    final context = Get.context;
    final isTablet = context != null ? ResponsiveUtils.isTablet(context) : false;

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 24.r),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 400 : double.infinity,
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.85,
          ),
          padding: EdgeInsets.all(isTablet ? 28 : 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon with glow
              Container(
                width: isTablet ? 80 : 72.w,
                height: isTablet ? 80 : 72.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF6D5FFD), Color(0xFFAB30FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 18.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.spa_rounded,
                  color: Colors.white,
                  size: isTablet ? 44 : 40.sp,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 20.h),
              // App name
              Text(
                'MoodShift AI',
                style: TextStyle(
                  fontSize: isTablet ? 26 : 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: isTablet ? 8 : 6.h),
              // Version
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 10.w,
                  vertical: isTablet ? 6 : 4.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16.r),
                ),
                child: Obx(() => Text(
                      'v${appVersion.value}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 13.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C4DFF),
                      ),
                    )),
              ),
              SizedBox(height: isTablet ? 24 : 20.h),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // About text
                      Text(
                        'about_text'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : 20.h),
                      // AI Disclaimer Section
                      _buildAboutSection(
                        title: 'about_ai_disclaimer_title'.tr,
                        content: 'about_ai_disclaimer_text'.tr,
                        icon: Icons.smart_toy_outlined,
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16.h),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection({
    required String title,
    required String content,
    required IconData icon,
    required bool isTablet,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 16 : 14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF7C4DFF),
                size: isTablet ? 20 : 18.sp,
              ),
              SizedBox(width: isTablet ? 8 : 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 10 : 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: isTablet ? 13 : 12.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void toggleCrashReports(bool enabled) {
    crashReportsEnabled.value = enabled;
    _crashlytics.setCrashReportsEnabled(enabled);

    SnackbarUtils.showCustom(
      title: 'crash_reports'.tr,
      message: enabled ? 'crash_reports_enabled'.tr : 'crash_reports_disabled'.tr,
      backgroundColor: const Color(0xFF6D5FFD),
      textColor: Colors.white,
      icon: Icons.bug_report_rounded,
      duration: const Duration(seconds: 3),
    );
  }
}

