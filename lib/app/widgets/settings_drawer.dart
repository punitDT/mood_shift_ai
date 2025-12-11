import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../modules/settings/settings_controller.dart';
import '../utils/responsive_utils.dart';

class SettingsDrawer extends GetView<SettingsController> {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final drawerWidth = isTablet ? 350.0 : MediaQuery.of(context).size.width * 0.85;

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFF0a0520),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0520),
              Color(0xFF150a2e),
              Color(0xFF0d0618),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(context, isTablet),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 20.w,
                    vertical: isTablet ? 16 : 20.h,
                  ),
                  children: [
                    _buildSettingItem(
                      icon: Icons.language_rounded,
                      title: 'language'.tr,
                      trailing: Obx(() => Text(
                            controller.selectedLanguage.value,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 14.sp,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          )),
                      onTap: controller.showLanguageSelector,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isTablet ? 12 : 12.h),
                    _buildSettingItem(
                      icon: Icons.record_voice_over_rounded,
                      title: 'voice_gender'.tr,
                      trailing: Obx(() => Text(
                            controller.selectedVoiceGender.value,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 14.sp,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          )),
                      onTap: controller.showVoiceGenderSelector,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isTablet ? 12 : 12.h),
                    _buildCrashReportsToggle(isTablet),
                    SizedBox(height: isTablet ? 12 : 12.h),
                    _buildSettingItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'privacy_policy'.tr,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: isTablet ? 16 : 16.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer first
                        controller.openPrivacyPolicy();
                      },
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isTablet ? 12 : 12.h),
                    _buildSettingItem(
                      icon: Icons.help_outline_rounded,
                      title: 'about'.tr,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: isTablet ? 16 : 16.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onTap: controller.showAbout,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isTablet ? 12 : 12.h),
                    _buildSettingItem(
                      icon: Icons.info_outline_rounded,
                      title: 'version'.tr,
                      trailing: Obx(() => Text(
                            controller.appVersion.value,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 14.sp,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          )),
                      onTap: null,
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20.w,
        vertical: isTablet ? 20 : 16.h,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: isTablet ? 26 : 24.sp,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8.w),
          Text(
            'settings'.tr,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 16.w,
          vertical: isTablet ? 16 : 16.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isTablet ? 24 : 24.sp,
            ),
            SizedBox(width: isTablet ? 16 : 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildCrashReportsToggle(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 16.w,
        vertical: isTablet ? 16 : 16.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bug_report_rounded,
            color: Colors.white,
            size: isTablet ? 24 : 24.sp,
          ),
          SizedBox(width: isTablet ? 16 : 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'crash_reports'.tr,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isTablet ? 4 : 4.h),
                Text(
                  'crash_reports_subtitle'.tr,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 13.sp,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isTablet ? 12 : 12.w),
          Obx(() => Switch(
                value: controller.crashReportsEnabled.value,
                onChanged: controller.toggleCrashReports,
                activeColor: const Color(0xFF6D5FFD),
                activeTrackColor: const Color(0xFF6D5FFD).withOpacity(0.5),
                inactiveThumbColor: Colors.white.withOpacity(0.7),
                inactiveTrackColor: Colors.white.withOpacity(0.2),
              )),
        ],
      ),
    );
  }
}

