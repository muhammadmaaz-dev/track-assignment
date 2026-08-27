import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:assignment_tracker/theme/constants.dart';

enum LegalDocType { privacyPolicy, termsOfService }

class LegalDocScreen extends StatelessWidget {
  final LegalDocType docType;

  const LegalDocScreen({super.key, required this.docType});

  String get _title => docType == LegalDocType.privacyPolicy
      ? 'Privacy Policy'
      : 'Terms of Service';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 28.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _title,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            docType == LegalDocType.privacyPolicy
                                ? Icons.shield_outlined
                                : Icons.article_outlined,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                docType == LegalDocType.privacyPolicy
                                    ? 'Privacy Policy'
                                    : 'Terms of Service',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Last updated: August 27, 2026',
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      docType == LegalDocType.privacyPolicy
                          ? 'Kato is built with privacy by design. Your data stays 100% on your device.'
                          : 'Please review the terms and conditions governing your use of the Kato app.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Content Sections
              if (docType == LegalDocType.privacyPolicy) ..._buildPrivacySections()
              else ..._buildTermsSections(),

              SizedBox(height: 24.h),

              // Contact Footer Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'If you have any questions regarding this document, please reach out to:',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildContactItem(Icons.business_outlined, 'Company', 'Xevon Labs'),
                    SizedBox(height: 8.h),
                    _buildContactItem(Icons.email_outlined, 'Email', 'xevonlabs@gmail.com'),
                  ],
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mutedText, size: 16.sp),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(color: AppColors.mutedText, fontSize: 13.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPrivacySections() {
    return [
      _buildSection(
        title: '1. Summary & Privacy by Design',
        content:
            '• Offline-First: All your tasks, assignments, quizzes, notes, marks, and attachments are saved locally on your device.\n'
            '• No Accounts: You do not need to register, log in, or provide personal identity info.\n'
            '• Zero Tracking: We do not collect analytics, telemetry, or behavioral tracking data.\n'
            '• User Controlled: Data only leaves your device when you explicitly choose to share it.',
      ),
      _buildSection(
        title: '2. Information Stored Locally',
        content:
            '• Task titles, descriptions, due dates, marks, and categories.\n'
            '• Selected attachments (stored in your app documents directory).\n'
            '• Notification and ring preferences.',
      ),
      _buildSection(
        title: '3. Device Permissions',
        content:
            '• Notifications & Exact Alarms: Used to trigger precise deadline reminders and countdown alerts.\n'
            '• Storage / File Picker: Used only when you choose to attach documents, PDFs, or images to tasks.\n'
            '• Vibration & Sound: Used to alert you when alarms fire.',
      ),
      _buildSection(
        title: '4. Third-Party AI Sharing',
        content:
            'Kato includes an optional "Share to AI" feature. When used, your task details and attachments are shared via your device\'s native share dialog with whatever external application or AI service you select. That data is governed by the chosen provider\'s privacy policy.',
      ),
      _buildSection(
        title: '5. Data Retention & Deletion',
        content:
            'Your data remains exclusively on your device until you delete tasks or uninstall the app. Uninstalling Kato permanently removes local app databases and cached attachments.',
      ),
    ];
  }

  List<Widget> _buildTermsSections() {
    return [
      _buildSection(
        title: '1. Acceptance of Terms',
        content:
            'By downloading or using Kato, you agree to these Terms of Service. If you do not agree, please do not use the app.',
      ),
      _buildSection(
        title: '2. Local Storage & Backups',
        content:
            '• Kato operates offline-first. Your data is stored on your device.\n'
            '• You are responsible for maintaining backups of your device. We are not liable for data loss resulting from device resets, app deletion, or hardware failure.',
      ),
      _buildSection(
        title: '3. Alarm & Notification Reliability',
        content:
            'The app relies on operating system alarms. System battery savers, "Do Not Disturb" modes, or OEM background restrictions may impact notification timing. Please verify critical academic deadlines independently.',
      ),
      _buildSection(
        title: '4. Academic Integrity & AI Usage',
        content:
            '• You agree not to use Kato or its AI sharing tools to violate academic honesty codes or institution policies.\n'
            '• Content generated by third-party AI tools is the responsibility of those respective providers.',
      ),
      _buildSection(
        title: '5. Intellectual Property & Disclaimer',
        content:
            '• The Kato app design, branding, and code are the intellectual property of Xevon Labs.\n'
            '• The app is provided "AS IS" without warranty of any kind. Xevon Labs is not liable for missed deadlines or indirect damages.',
      ),
    ];
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              content,
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
