import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../widgets/task_widgets.dart';
import 'new_task_sheet.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dummy data representing real-time data
  List<Task> todaysFocusTasks = [
    Task(
      id: '1',
      title: 'Interaction Design Final Prototype',
      type: 'PROJECT',
      dueDate: DateTime.now().add(const Duration(hours: 4)),
      timeString: 'DUE 4:00 PM',
      isHighPriority: true,
    ),
    Task(
      id: '2',
      title: 'Microeconomics Problem Set 4',
      type: 'ASSIGNMENT',
      dueDate: DateTime.now().add(const Duration(hours: 11)),
      timeString: 'DUE 11:59 PM',
      isHighPriority: false,
    ),
    Task(
      id: '3',
      title: 'Cloud Computing Weekly Quiz',
      type: 'QUIZ',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      timeString: '20 MINS',
      isHighPriority: false,
    ),
  ];

  List<Task> upcomingTasks = [
    Task(
      id: '4',
      title: 'Advanced Algorithms Essay',
      type: 'ASSIGNMENT',
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    Task(
      id: '5',
      title: 'Modern Art History Presentation',
      type: 'PROJECT',
      dueDate: DateTime.now().add(const Duration(days: 4)),
    ),
    Task(
      id: '6',
      title: 'Philosophy Mid-Term Prep',
      type: 'QUIZ',
      dueDate: DateTime.now().add(const Duration(days: 30)), // Oct 30 dummy
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useSafeArea: true,
              builder: (context) => const NewTaskSheet(),
            );
          },
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Focus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${todaysFocusTasks.length} TASKS',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Today's Focus List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todaysFocusTasks.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(task: todaysFocusTasks[index]),
                        ),
                      );
                    },
                    child: TodaysFocusCard(task: todaysFocusTasks[index]),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Upcoming Header
              const Text(
                'Upcoming',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Upcoming List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingTasks.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey.shade800, height: 1),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(task: upcomingTasks[index]),
                        ),
                      );
                    },
                    child: UpcomingTaskTile(task: upcomingTasks[index]),
                  );
                },
              ),
              const SizedBox(height: 80), // Fab space
            ],
          ),
        ),
      ),
    );
  }
}
