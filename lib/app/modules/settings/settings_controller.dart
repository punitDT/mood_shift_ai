import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/storage_service.dart';

class SettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final appVersion = ''.obs;
  final selectedLanguage = 'English'.obs;
  final selectedVoiceGender = 'Female'.obs;

  final languages = [
    {'code': 'en', 'country': 'US', 'name': 'english'},
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
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion.value = packageInfo.version;
  }

  void _loadCurrentLanguage() {
    final currentCode = _storage.getLanguageCode();
    final lang = languages.firstWhere(
      (l) => l['code'] == currentCode,
      orElse: () => languages[0],
    );
    selectedLanguage.value = lang['name']!.tr;
  }

  void _loadCurrentVoiceGender() {
    final currentGender = _storage.getVoiceGender();
    selectedVoiceGender.value = currentGender == 'male' ? 'male'.tr : 'female'.tr;
  }

  void showLanguageSelector() {
    Get.dialog(
      AlertDialog(
        title: Text('select_language'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              return ListTile(
                title: Text(lang['name']!.tr),
                onTap: () {
                  _changeLanguage(
                    lang['code']!,
                    lang['country']!,
                    lang['name']!,
                  );
                  Get.back();
                },
              );
            },
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
    Get.dialog(
      AlertDialog(
        title: Text('voice_gender'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.male, color: Colors.blue),
                title: Text('male'.tr),
                onTap: () {
                  Get.back(); // Close dialog first
                  _changeVoiceGender('male');
                },
              ),
              ListTile(
                leading: const Icon(Icons.female, color: Colors.pink),
                title: Text('female'.tr),
                onTap: () {
                  Get.back(); // Close dialog first
                  _changeVoiceGender('female');
                },
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

    Get.snackbar(
      'voice_gender'.tr,
      message,
      backgroundColor: Colors.deepPurple.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> openPrivacyPolicy() async {
    // TODO: Replace with your actual privacy policy URL
    const url = 'https://your-privacy-policy-url.com';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open privacy policy');
    }
  }

  Future<void> rateApp() async {
    // TODO: Replace with your actual app store URLs
    const androidUrl = 'https://play.google.com/store/apps/details?id=com.moodshift.ai';
    const iosUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';
    
    final url = GetPlatform.isAndroid ? androidUrl : iosUrl;
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open app store');
    }
  }

  void shareApp() {
    Share.share('share_text'.tr);
  }

  void showAbout() {
    Get.dialog(
      AlertDialog(
        title: Text('about'.tr),
        content: Text('about_text'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

