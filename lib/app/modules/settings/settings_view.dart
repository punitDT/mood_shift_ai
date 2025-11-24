import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'settings_controller.dart';
import '../../controllers/ad_free_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a0f2e),
              const Color(0xFF2d1b4e),
              const Color(0xFF4a2c6f),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              _buildTopBar(),

              // Settings List
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  children: [
                    _buildAdFreeStatus(),

                    SizedBox(height: 12.h),

                    _buildSettingItem(
                      icon: Icons.info_outline_rounded,
                      title: 'version'.tr,
                      trailing: Obx(() => Text(
                            controller.appVersion.value,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          )),
                      onTap: null,
                    ),

                    SizedBox(height: 12.h),

                    _buildSettingItem(
                      icon: Icons.language_rounded,
                      title: 'language'.tr,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() => Text(
                                controller.selectedLanguage.value,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              )),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16.sp,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ],
                      ),
                      onTap: controller.showLanguageSelector,
                    ),

                    SizedBox(height: 12.h),

                    _buildSettingItem(
                      icon: Icons.record_voice_over_rounded,
                      title: 'voice_gender'.tr,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() => Text(
                                controller.selectedVoiceGender.value,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              )),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16.sp,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ],
                      ),
                      onTap: controller.showVoiceGenderSelector,
                    ),

                    SizedBox(height: 12.h),
                    
                    _buildSettingItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'privacy_policy'.tr,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onTap: controller.openPrivacyPolicy,
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildSettingItem(
                      icon: Icons.star_outline_rounded,
                      title: 'rate_app'.tr,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onTap: controller.rateApp,
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildSettingItem(
                      icon: Icons.share_rounded,
                      title: 'share_app'.tr,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onTap: controller.shareApp,
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildSettingItem(
                      icon: Icons.help_outline_rounded,
                      title: 'about'.tr,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onTap: controller.showAbout,
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

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'settings'.tr,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
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
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
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

  Widget _buildAdFreeStatus() {
    final adFreeController = Get.find<AdFreeController>();

    return Obx(() {
      final isAdFree = adFreeController.isAdFree.value;
      final timeRemaining = adFreeController.adFreeTimeRemaining.value;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAdFree
                ? [
                    Colors.green.withOpacity(0.3),
                    Colors.teal.withOpacity(0.3),
                  ]
                : [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isAdFree
                ? Colors.green.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAdFree ? Icons.spa_rounded : Icons.block_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ad_free_status'.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isAdFree
                        ? '${'ad_free_active'.tr}$timeRemaining'
                        : 'no_ads_active'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isAdFree)
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24.sp,
              ),
          ],
        ),
      );
    });
  }
}

