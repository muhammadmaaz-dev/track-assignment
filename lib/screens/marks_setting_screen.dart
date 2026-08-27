import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:assignment_tracker/theme/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarksSettingScreen extends StatefulWidget {
  const MarksSettingScreen({super.key});

  @override
  State<MarksSettingScreen> createState() => _MarksSettingScreenState();
}

class _MarksSettingScreenState extends State<MarksSettingScreen> {
  final TextEditingController _assignmentController = TextEditingController();
  final TextEditingController _quizController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _assignmentController.text = (prefs.getInt('marks_ASSIGNMENT') ?? 0)
          .toString();
      _quizController.text = (prefs.getInt('marks_QUIZ') ?? 0).toString();
      _projectController.text = (prefs.getInt('marks_PROJECT') ?? 0).toString();
    });
  }

  Future<void> _saveMarks() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'marks_ASSIGNMENT',
      int.tryParse(_assignmentController.text) ?? 0,
    );
    await prefs.setInt('marks_QUIZ', int.tryParse(_quizController.text) ?? 0);
    await prefs.setInt(
      'marks_PROJECT',
      int.tryParse(_projectController.text) ?? 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _assignmentController.dispose();
    _quizController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  Widget _buildMarkInput(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.element,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 13.6.w,
                  vertical: 6.8.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 27.w),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Marks',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Configure maximum marks for your tasks.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Column(
                  children: [
                    _buildMarkInput('Assignment', _assignmentController),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    _buildMarkInput('Quiz', _quizController),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    _buildMarkInput('Project', _projectController),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMarks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 13.6.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    'Save Marks',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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
}
