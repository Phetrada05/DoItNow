import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_page.dart';
import '../models/task_model.dart';
import 'all_task_list_page.dart';
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
    tasks: [
      Task(title: "Flutter UI"),
    ],
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String filter = "all";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
   Future<List<Task>> _getUpcomingTasksFromFirebase() async {
    List<Task> allTasks = [];
    
    try {
      final subjectsSnapshot = await _firestore.collection('subjects').get();
      
      for (var subjectDoc in subjectsSnapshot.docs) {
        final tasksSnapshot = await _firestore
            .collection('subjects')
            .doc(subjectDoc.id)
            .collection('tasks')
            .get();
        
        for (var taskDoc in tasksSnapshot.docs) {
          final data = taskDoc.data();
          final dueDate = data['dueDate'] as Timestamp?;
          final status = data['status'] ?? 'todo';
          
          if (dueDate != null && status != 'done') {
            allTasks.add(Task(
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              dueDate: dueDate.toDate(),
              status: TaskStatus.values.firstWhere(
                (e) => e.name == status,
                orElse: () => TaskStatus.todo,
              ),
            ));
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
      final subjectsSnapshot = await _firestore.collection('subjects').get();

      for (var subjectDoc in subjectsSnapshot.docs) {
        final tasksSnapshot = await _firestore
            .collection('subjects')
            .doc(subjectDoc.id)
            .collection('tasks')
            .get();

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
              const Text(
                "เพิ่มวิชาใหม่",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "ชื่อวิชา",
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await _firestore.collection('subjects').add({
                      'name': controller.text,
                      'createdAt': Timestamp.now(),
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text("เพิ่ม"),
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
    final tasksSnapshot = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('tasks')
        .get();

    for (var taskDoc in tasksSnapshot.docs) {
      await taskDoc.reference.delete();
    }

    // Then delete the subject itself
    await _firestore.collection('subjects').doc(subjectId).delete();

    setState(() {});
  }

  void _showDeleteSubjectDialog(String subjectId, String subjectName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ลบวิชา"),
          content: Text("คุณแน่ใจหรือไม่ที่จะลบ \"$subjectName\" และงานทั้งหมดในนั้น?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteSubject(subjectId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("ลบ", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
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
                children: const [
                  SizedBox(height: 10),
                  Text(
                    "✨ DoItNow ✨",
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "จัดการงานของคุณให้สำเร็จ 🚀",
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
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

                  final data = snapshot.data ?? {'total': 0, 'completed': 0, 'pending': 0};
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
                                pending, "ค้างอยู่",
                                Colors.pink.shade100),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: summaryCard(
                                completed, "เสร็จแล้ว",
                                Colors.pink.shade200),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: summaryCard(
                                total, "ทั้งหมด",
                                Colors.grey.shade300),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "ความคืบหน้ารวม",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: Colors.pink,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${(progress * 100).toStringAsFixed(0)} %",
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 25),
           

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "Upcoming Tasks",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
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
      child: const Text("ดูทั้งหมด"),
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
      return const Text(
        "ไม่มีงานที่กำลังจะมาถึง 🎉",
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
                      color: getStatusColor(task.status)
                          .withOpacity(0.2),
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
                  "Due: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
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
              const Text(
                "My Subjects",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('subjects').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final subjectDocs = snapshot.data!.docs;

                  if (subjectDocs.isEmpty) {
                    return const Center(child: Text("ยังไม่มีวิชา"));
                  }

                  return Column(
                    children: subjectDocs.map((doc) {
                      final subjectId = doc.id;
                      final subjectName = doc['name'] as String;

                    return GestureDetector(
                        onTap: () {
                          final subject = Subject(
                            name: subjectName,
                            tasks: [],
                          );
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
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    subjectName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _showDeleteSubjectDialog(subjectId, subjectName);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('subjects')
                                    .doc(subjectId)
                                    .collection('tasks')
                                    .snapshots(),
                                builder: (context, taskSnapshot) {
                                  if (!taskSnapshot.hasData)
                                    return const Text("0 / 0 งาน");

                                  final tasks = taskSnapshot.data!.docs;
                                  final done = tasks
                                      .where((t) =>
                                          (t['status'] ?? 'todo') == 'done')
                                      .length;

                                  return Text("${done} / ${tasks.length} งาน");
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
  }

  Widget summaryCard(
      int number,
      String title,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            number.toString(),
            style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }
}