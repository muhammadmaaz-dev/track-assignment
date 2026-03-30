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
  List<Task> allTasks = [
    Task(
      id: '1',
      title: 'Interaction Design Final Prototype',
      type: 'PROJECT',
      dueDate: DateTime.now().add(const Duration(hours: 4)), // Today
    ),
    Task(
      id: '2',
      title: 'Microeconomics Problem Set 4',
      type: 'ASSIGNMENT',
      dueDate: DateTime.now().add(const Duration(hours: 1)), // Today (Earliest)
    ),
    Task(
      id: '3',
      title: 'Cloud Computing Weekly Quiz',
      type: 'QUIZ',
      dueDate: DateTime.now().add(
        const Duration(days: 1, hours: 4),
      ), // Tomorrow 4 PM
    ),
    Task(
      id: '4',
      title: 'Advanced Algorithms Essay',
      type: 'ASSIGNMENT',
      dueDate: DateTime.now().add(
        const Duration(days: 1, hours: 2),
      ), // Tomorrow 2 PM
    ),
  ];

  List<Task> todaysFocusTasks = [];
  List<Task> upcomingTasks = [];

  @override
  void initState() {
    super.initState();
    _organizetask();
  }

  void _organizetask() {
    final now = DateTime.now();

    todaysFocusTasks.clear();
    upcomingTasks.clear();

    for (var task in allTasks) {
      bool isToday =
          task.dueDate.year == now.year &&
          task.dueDate.month == now.month &&
          task.dueDate.day == now.day;

      if (isToday) {
        todaysFocusTasks.add(task);
      } else if (task.dueDate.isAfter(now)) {
        upcomingTasks.add(task);
      }
    }
    todaysFocusTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          // 1. Is function ko 'async' banayein
          onPressed: () async {
            // 2. Naya task aane ka wait karein
            final Task? newTask = await showModalBottomSheet<Task>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useSafeArea: true,
              builder: (context) => const NewTaskSheet(),
            );

            // 3. Agar user ne task add kiya hai (cancel nahi kiya) to list me daal dein
            if (newTask != null) {
              setState(() {
                allTasks.add(newTask); // Main list me add karein
                _organizetask(); // Dobara sort aur filter karein
              });
            }
          },
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.black),
          shape: const CircleBorder(),
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
                  bool isTopTask = index == 0;
                  Task originalTask = todaysFocusTasks[index];

                  Task displayTask = Task(
                    id: originalTask.id,
                    title: originalTask.title,
                    type: originalTask.type,
                    dueDate: originalTask.dueDate,
                    timeString: originalTask.timeString,
                    isHighPriority: isTopTask,
                    description: originalTask.description,
                  );

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskDetailScreen(task: originalTask),
                        ),
                      );
                    },
                    child: TodaysFocusCard(task: displayTask),
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
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskDetailScreen(task: upcomingTasks[index]),
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
