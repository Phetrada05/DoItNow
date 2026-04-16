import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_page.dart';
import '../models/task_model.dart';
import 'all_task_list_page.dart';
import '../services/app_language.dart';
import '../services/firestore_user_scope.dart';
// ================= GLOBAL DATA =================

List<Subject> subjects = [
  Subject(
    name: "Math",
    tasks: [
      Task(title: "Homework 1"),
      Task(title: "Quiz", status: TaskStatus.done),
    ],
  ),
  Subject(
    name: "Mobile Dev",
    tasks: [Task(title: "Flutter UI")],
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static bool _notificationShownThisSession = false;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String filter = "all";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String tr(String th, String en) => AppLanguage.instance.text(th, en);

  Future<void> _onLanguageSelected(String code) async {
    await AppLanguage.instance.setLanguage(code);
  }

  @override
  void initState() {
    super.initState();
    _checkUpcomingTasks();
  }

  // ================= CHECK UPCOMING TASKS FOR NOTIFICATION =================

  Future<void> _checkUpcomingTasks() async {
    // ถ้าแสดง notification ไปแล้วในรอบนี้ → ไม่แสดงซ้ำ
    if (HomePage._notificationShownThisSession) {
      return;
    }

    if (!mounted) return;

    try {
      final allTasks = await _getUpcomingTasksFromFirebase();

      // ตรวจสอบงานที่ใกล้วันกำหนด (ภายใน 3 วันข้างหน้า)
      final now = DateTime.now();
      final threeDaysLater = now.add(const Duration(days: 3));

      final upcomingTasks = allTasks.where((task) {
        if (task.dueDate == null) return false;
        return task.dueDate!.isAfter(now) &&
            task.dueDate!.isBefore(threeDaysLater);
      }).toList();

      // แสดง notification ถ้ามีงานใกล้วันกำหนด
      if (upcomingTasks.isNotEmpty && mounted) {
        HomePage._notificationShownThisSession = true;
        _showUpcomingTasksAlert(upcomingTasks);
      }
    } catch (e) {
      print('Error checking upcoming tasks: $e');
    }
  }

  void _showUpcomingTasksAlert(List<Task> tasks) {
    showDialog(
      context: context,
      barrierDismissible: false, // บังคับให้กด "รับทราบ"
      builder: (context) {
        return AlertDialog(
          title: Text(
            tr('⏰ แจ้งเตือนงาน', '⏰ Task Reminder'),
            style: TextStyle(color: Colors.orange),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('งานต่อไปนี้กำลังจะมาถึง:', 'These tasks are coming soon:')),
                const SizedBox(height: 12),
                ...tasks.map((task) {
                  final daysLeft = task.dueDate!
                      .difference(DateTime.now())
                      .inDays;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${tr('กำหนดส่ง', 'Due')}: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year} ${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (daysLeft == 0)
                            Text(
                              tr('⚠️ วันนี้!', '⚠️ Today!'),
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else if (daysLeft == 1)
                            Text(
                              tr('⚠️ พรุ่งนี้!', '⚠️ Tomorrow!'),
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            Text(
                              tr('⏳ อีก $daysLeft วัน', '⏳ In $daysLeft days'),
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: Text(
                tr('รับทราบ', 'OK'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Task>> _getUpcomingTasksFromFirebase() async {
    List<Task> allTasks = [];

    try {
      final subjectsSnapshot = await FirestoreUserScope.subjects(
        _firestore,
      ).get();

      for (var subjectDoc in subjectsSnapshot.docs) {
        final tasksSnapshot = await FirestoreUserScope.tasks(
          _firestore,
          subjectDoc.id,
        ).get();

        for (var taskDoc in tasksSnapshot.docs) {
          final data = taskDoc.data();
          final dueDate = data['dueDate'] as Timestamp?;
          final status = data['status'] ?? 'todo';

          if (dueDate != null && status != 'done') {
            allTasks.add(
              Task(
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                dueDate: dueDate.toDate(),
                status: TaskStatus.values.firstWhere(
                  (e) => e.name == status,
                  orElse: () => TaskStatus.todo,
                ),
              ),
            );
          }
        }
      }

      allTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      return allTasks;
    } catch (e) {
      return [];
    }
  }

  // ================= FILTER =================

  List<Task> getFilteredTasks(List<Task> tasks) {
    if (filter == "active") {
      return tasks.where((t) => !t.completed).toList();
    } else if (filter == "completed") {
      return tasks.where((t) => t.completed).toList();
    }
    return tasks;
  }

  Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.orange;
      case TaskStatus.doing:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
  }
  // ================= SUMMARY =================

  Future<Map<String, int>> _getTaskSummary() async {
    int total = 0;
    int completed = 0;

    try {
      final subjectsSnapshot = await FirestoreUserScope.subjects(
        _firestore,
      ).get();

      for (var subjectDoc in subjectsSnapshot.docs) {
        final tasksSnapshot = await FirestoreUserScope.tasks(
          _firestore,
          subjectDoc.id,
        ).get();

        for (var taskDoc in tasksSnapshot.docs) {
          total++;
          final status = taskDoc['status'] ?? 'todo';
          if (status == 'done') {
            completed++;
          }
        }
      }

      return {
        'total': total,
        'completed': completed,
        'pending': total - completed,
      };
    } catch (e) {
      return {'total': 0, 'completed': 0, 'pending': 0};
    }
  }

  // ================= ADD SUBJECT =================

  void showAddSubjectDialog() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('เพิ่มวิชาใหม่', 'Add New Subject'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: tr('ชื่อวิชา', 'Subject name')),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await FirestoreUserScope.subjects(_firestore).add({
                      'name': controller.text,
                      'createdAt': Timestamp.now(),
                      'userId': FirestoreUserScope.requireUid(),
                    });
                  }
                  Navigator.pop(context);
                },
                child: Text(tr('เพิ่ม', 'Add')),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= DELETE SUBJECT =================

  Future<void> _deleteSubject(String subjectId) async {
    // First, delete all tasks in this subject
    final tasksSnapshot = await FirestoreUserScope.tasks(
      _firestore,
      subjectId,
    ).get();

    for (var taskDoc in tasksSnapshot.docs) {
      await taskDoc.reference.delete();
    }

    // Then delete the subject itself
    await FirestoreUserScope.subjectDoc(_firestore, subjectId).delete();

    setState(() {});
  }

  void _showDeleteSubjectDialog(String subjectId, String subjectName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('ลบวิชา', 'Delete Subject')),
          content: Text(
            tr(
              'คุณแน่ใจหรือไม่ที่จะลบ "$subjectName" และงานทั้งหมดในนั้น?',
              'Are you sure you want to delete "$subjectName" and all its tasks?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('ยกเลิก', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteSubject(subjectId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(tr('ลบ', 'Delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F4),

          floatingActionButton: FloatingActionButton(
            onPressed: showAddSubjectDialog,
            backgroundColor: Colors.pink,
            child: const Icon(Icons.add, color: Colors.white),
          ),

          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
            children: [
              /// HEADER
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: tr('เลือกภาษา', 'Choose language'),
                        onSelected: (code) {
                          _onLanguageSelected(code);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'th',
                            child: Text(tr('ไทย', 'Thai')),
                          ),
                          PopupMenuItem<String>(
                            value: 'en',
                            child: Text(tr('อังกฤษ', 'English')),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.language, color: Colors.pink),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "✨ DoItNow ✨",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('จัดการงานของคุณให้สำเร็จ 🚀', 'Get your tasks done 🚀'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              /// SUMMARY CARDS
              FutureBuilder<Map<String, int>>(
                future: _getTaskSummary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data =
                      snapshot.data ??
                      {'total': 0, 'completed': 0, 'pending': 0};
                  final pending = data['pending'] ?? 0;
                  final completed = data['completed'] ?? 0;
                  final total = data['total'] ?? 0;
                  final progress = total == 0 ? 0.0 : completed / total;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: summaryCard(
                              pending,
                              tr('ค้างอยู่', 'Pending'),
                              Colors.pink.shade100,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: summaryCard(
                              completed,
                              tr('เสร็จแล้ว', 'Completed'),
                              Colors.pink.shade200,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: summaryCard(
                              total,
                              tr('ทั้งหมด', 'Total'),
                              Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        tr('ความคืบหน้ารวม', 'Overall Progress'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: Colors.pink,
                      ),
                      const SizedBox(height: 5),
                      Text("${(progress * 100).toStringAsFixed(0)} %"),
                    ],
                  );
                },
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('งานที่ใกล้ถึงกำหนด', 'Upcoming Tasks'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllTaskListPage(),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    child: Text(tr('ดูทั้งหมด', 'View all')),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              FutureBuilder<List<Task>>(
                future: _getUpcomingTasksFromFirebase(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text(
                      tr('ไม่มีงานที่กำลังจะมาถึง 🎉', 'No upcoming tasks 🎉'),
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  final upcomingTasks = snapshot.data!;

                  return Column(
                    children: upcomingTasks.map((task) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(
                                      task.status,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    task.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: getStatusColor(task.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (task.dueDate != null)
                              Text(
                                "${tr('กำหนดส่ง', 'Due')}: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              /// เส้นคั่นก่อน My Subjects
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 20),

              /// MY SUBJECTS
              Text(
                tr('วิชาของฉัน', 'My Subjects'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirestoreUserScope.subjects(_firestore).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final subjectDocs = snapshot.data!.docs;

                  if (subjectDocs.isEmpty) {
                    return Center(child: Text(tr('ยังไม่มีวิชา', 'No subjects yet')));
                  }

                  return Column(
                    children: subjectDocs.map((doc) {
                      final subjectId = doc.id;
                      final subjectName = doc['name'] as String;

                      return GestureDetector(
                        onTap: () {
                          final subject = Subject(name: subjectName, tasks: []);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubjectPage(
                                subject: subject,
                                subjectId: subjectId,
                              ),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    subjectName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      _showDeleteSubjectDialog(
                                        subjectId,
                                        subjectName,
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirestoreUserScope.tasks(
                                  _firestore,
                                  subjectId,
                                ).snapshots(),
                                builder: (context, taskSnapshot) {
                                  if (!taskSnapshot.hasData)
                                    return Text(tr('0 / 0 งาน', '0 / 0 tasks'));

                                  final tasks = taskSnapshot.data!.docs;
                                  final done = tasks
                                      .where(
                                        (t) =>
                                            (t['status'] ?? 'todo') == 'done',
                                      )
                                      .length;

                                  return Text(
                                    tr('${done} / ${tasks.length} งาน', '${done} / ${tasks.length} tasks'),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              const LinearProgressIndicator(
                                value: 0.5,
                                color: Colors.pink,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget summaryCard(int number, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            number.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }
}
