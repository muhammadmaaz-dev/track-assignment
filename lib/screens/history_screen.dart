import 'package:assignment_tracker/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import 'task_detail_screen.dart';
import '../services/db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTabIndex = 0;
  List<Task> allHistoryTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryTasks();
    DatabaseHelper.instance.onDatabaseChanged.addListener(_onDbChanged);
  }

  void _onDbChanged() {
    if (mounted) {
      _loadHistoryTasks();
    }
  }

  @override
  void dispose() {
    DatabaseHelper.instance.onDatabaseChanged.removeListener(_onDbChanged);
    super.dispose();
  }

  Future<void> _loadHistoryTasks() async {
    try {
      final allTasks = await DatabaseHelper.instance.getAllTasks();

      final now = DateTime.now();

      if (mounted) {
        setState(() {
          allHistoryTasks = allTasks.where((task) {
            bool isPastDue =
                task.dueDate.isBefore(now) &&
                !(task.dueDate.year == now.year &&
                    task.dueDate.month == now.month &&
                    task.dueDate.day == now.day);
            // Make sure overdue only counts strictly past days, or just use isBefore(now).
            // Since home screen uses isBefore(now) to still show today's tasks if not past the exact time.
            return task.isCompleted || task.dueDate.isBefore(now);
          }).toList();

          // Sort newest first
          allHistoryTasks.sort((a, b) => b.dueDate.compareTo(a.dueDate));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history tasks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _calculateSuccessRate() {
    if (allHistoryTasks.isEmpty) return 0.0;
    int completedCount = allHistoryTasks
        .where((task) => task.isCompleted)
        .length;
    return (completedCount / allHistoryTasks.length) * 100;
  }

  List<Task> get _filteredTasks {
    final now = DateTime.now();
    if (_selectedTabIndex == 0) {
      return allHistoryTasks; // ALL
    } else if (_selectedTabIndex == 1) {
      return allHistoryTasks
          .where((task) => task.isCompleted)
          .toList(); // COMPLETED
    } else {
      return allHistoryTasks
          .where((task) => !task.isCompleted && task.dueDate.isBefore(now))
          .toList(); // OVERDUE
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 17.w),
              child: Row(
                children: [
                  _buildTab('All', 0),
                  SizedBox(width: 12.w),
                  _buildTab('Completed', 1),
                  SizedBox(width: 12.w),
                  _buildTab('Overdue', 2),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Stats Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 17.w),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Success Rate',
                      value: '${_calculateSuccessRate().toInt()}%',
                      icon: Icons.trending_up,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Tasks',
                      value: '${allHistoryTasks.length}',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Recent Archive Section Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Recent Archive',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Archive List
            _isLoading
                ? SizedBox.shrink() // Prevents flicker
                : _filteredTasks.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(40.0.w),
                    child: Center(
                      child: Text(
                        'No history available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 17.w),
                    child: Column(
                      children: [
                        ..._filteredTasks.map((task) {
                          final now = DateTime.now();
                          final isOverdue =
                              !task.isCompleted && task.dueDate.isBefore(now);

                          List<Widget> footers = [];
                          if (task.isHighPriority) {
                            footers.add(
                              _buildFooterItem(
                                Icons.priority_high,
                                'High Priority',
                              ),
                            );
                          }
                          if (task.timeString != null) {
                            footers.add(
                              _buildFooterItem(
                                Icons.access_time,
                                task.timeString!,
                              ),
                            );
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetailScreen(
                                      task: task,
                                      isFromHistory: true,
                                    ),
                                  ),
                                ).then((_) {
                                  // Refresh when coming back
                                  _loadHistoryTasks();
                                });
                              },
                              child: _buildArchiveCard(
                                title: task.title,
                                date: DateFormat(
                                  'MMM d, yyyy',
                                ).format(task.dueDate),
                                isOverdue: isOverdue,
                                isCompleted: task.isCompleted,
                                footers: footers.isEmpty
                                    ? [
                                        _buildFooterItem(
                                          Icons.info_outline,
                                          task.type.toSentenceCase(),
                                        ),
                                      ]
                                    : footers,
                              ),
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: Colors.white, size: 20.4.w),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard({
    required String title,
    required String date,
    required bool isOverdue,
    required bool isCompleted,
    required List<Widget> footers,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.5.w,
                  vertical: 5.1.h,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.white.withOpacity(0.1)
                      : (isOverdue
                            ? Colors.red.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20.r),
                  border: isCompleted
                      ? null
                      : (isOverdue
                            ? Border.all(color: Colors.red.withOpacity(0.3))
                            : Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              )),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCompleted) ...[
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                    ],
                    Text(
                      isCompleted
                          ? 'Done'
                          : (isOverdue ? 'Overdue' : 'Pending'),
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.white
                            : (isOverdue
                                  ? Colors.red.shade300
                                  : Colors.orange.shade300),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            date,
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              for (int i = 0; i < footers.length; i++) ...[
                footers[i],
                if (i < footers.length - 1) SizedBox(width: 20.w),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey, size: 13.6.w),
        SizedBox(width: 6.w),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
