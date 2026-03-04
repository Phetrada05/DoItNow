import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class AllTaskListPage extends StatefulWidget {
  const AllTaskListPage({super.key});

  @override
  State<AllTaskListPage> createState() => _AllTaskListPageState();
}

class _AllTaskListPageState extends State<AllTaskListPage> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> toggleComplete(
      String subjectId, String taskDocId, TaskStatus currentStatus) async {
    if (subjectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาด: ไม่พบ Subject ID")),
      );
      return;
    }

    final newStatus = currentStatus == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;

    try {
      await _firestore
          .collection('subjects')
          .doc(subjectId)
          .collection('tasks')
          .doc(taskDocId)
          .update({'status': newStatus.name});
    } catch (e) {
      print('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
        );
      }
    }
  }

  void changeStatus(
      String subjectId, String taskDocId, TaskStatus currentStatus) {
    if (subjectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาด: ไม่พบ Subject ID")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("TODO"),
              onTap: () async {
                try {
                  await _firestore
                      .collection('subjects')
                      .doc(subjectId)
                      .collection('tasks')
                      .doc(taskDocId)
                      .update({'status': TaskStatus.todo.name});
                  Navigator.pop(context);
                } catch (e) {
                  print('Error: $e');
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                    );
                  }
                }
              },
            ),
            ListTile(
              title: const Text("DOING"),
              onTap: () async {
                try {
                  await _firestore
                      .collection('subjects')
                      .doc(subjectId)
                      .collection('tasks')
                      .doc(taskDocId)
                      .update({'status': TaskStatus.doing.name});
                  Navigator.pop(context);
                } catch (e) {
                  print('Error: $e');
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                    );
                  }
                }
              },
            ),
            ListTile(
              title: const Text("DONE"),
              onTap: () async {
                try {
                  await _firestore
                      .collection('subjects')
                      .doc(subjectId)
                      .collection('tasks')
                      .doc(taskDocId)
                      .update({'status': TaskStatus.done.name});
                  Navigator.pop(context);
                } catch (e) {
                  print('Error: $e');
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Task _mapToTask(Map<String, dynamic> data) {
    return Task(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      status: _parseStatus(data['status'] ?? 'todo'),
    );
  }

  TaskStatus _parseStatus(String status) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => TaskStatus.todo,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text("All Tasks"),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collectionGroup('tasks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final taskDocs = snapshot.data!.docs;

          if (taskDocs.isEmpty) {
            return const Center(
              child: Text("ยังไม่มีงาน"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: taskDocs.length,
            itemBuilder: (context, index) {
              final taskDoc = taskDocs[index];
              final taskDocId = taskDoc.id;
              final taskData = taskDoc.data() as Map<String, dynamic>;
              final task = _mapToTask(taskData);
              
              // ดึง subjectId จาก path: subjects/{subjectId}/tasks/{taskDocId}
              final subjectId = taskDoc.reference.parent.parent?.id ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// TITLE + STATUS + CHECK
                    Row(
                      children: [

                        /// ติ๊กเสร็จ
                        IconButton(
                          icon: Icon(
                            task.status == TaskStatus.done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: task.status == TaskStatus.done
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onPressed: () =>
                              toggleComplete(subjectId, taskDocId, task.status),
                        ),

                        /// Title
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration:
                                  task.status == TaskStatus.done
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                        ),

                        /// Status Badge (กดเปลี่ยนได้)
                        GestureDetector(
                          onTap: () =>
                              changeStatus(subjectId, taskDocId, task.status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(task.status)
                                  .withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Text(
                              task.status.name.toUpperCase(),
                              style: TextStyle(
                                color:
                                    getStatusColor(task.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// Description
                    Text(
                      task.description.isEmpty
                          ? "-"
                          : task.description,
                    ),

                    const SizedBox(height: 6),

                    /// Due date
                    Text(
                      "Due: ${formatDate(task.dueDate)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}