import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'task_detail_page.dart';
import '../services/app_language.dart';
import '../services/firestore_user_scope.dart';

class SubjectPage extends StatefulWidget {
  final Subject subject;
  final String? subjectId; // เพิ่ม Firebase ID

  const SubjectPage({super.key, required this.subject, this.subjectId});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String tr(String th, String en) => AppLanguage.instance.text(th, en);

  // ================= ADD / EDIT =================

  void showTaskDialog({Task? task, int? index}) {
    final titleController = TextEditingController(text: task?.title ?? "");
    final descController = TextEditingController(text: task?.description ?? "");

    DateTime? selectedDate = task?.dueDate;
    TaskStatus selectedStatus = task?.status ?? TaskStatus.todo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDateTime() async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (date == null) return;

              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (time == null) return;

              setModalState(() {
                selectedDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task == null
                        ? tr('เพิ่มงานใหม่', 'Add New Task')
                        : tr('แก้ไขงาน', 'Edit Task'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: tr('ชื่องาน', 'Task title')),
                  ),

                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: tr('รายละเอียด', 'Description')),
                  ),

                  const SizedBox(height: 15),

                  /// 🔥 เลือกสถานะ
                  DropdownButtonFormField<TaskStatus>(
                    value: selectedStatus,
                    decoration: InputDecoration(labelText: tr('สถานะ', 'Status')),
                    items: TaskStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: pickDateTime,
                    child: Text(tr('เลือกวัน/เวลา', 'Select date/time')),
                  ),

                  if (selectedDate != null)
                    Text(
                      "${tr('กำหนดส่ง', 'Due')}: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} "
                      "${selectedDate!.hour}:${selectedDate!.minute.toString().padLeft(2, '0')}",
                    ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    onPressed: () async {
                      if (titleController.text.isEmpty) return;

                      // บันทึกลง Firebase
                      if (widget.subjectId != null) {
                        try {
                          await FirestoreUserScope.tasks(
                            _firestore,
                            widget.subjectId!,
                          ).add({
                            'title': titleController.text,
                            'description': descController.text,
                            'dueDate': selectedDate,
                            'status': selectedStatus.name,
                            'subjectId': widget.subjectId,
                            'createdAt': Timestamp.now(),
                            'userId': FirestoreUserScope.requireUid(),
                          });
                        } catch (e) {
                          print('Error adding task: $e');
                        }
                      }

                      Navigator.pop(context);
                    },
                    child: Text(tr('บันทึก', 'Save')),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= CONFIRM DELETE =================

  // ================= UPDATE STATUS =================

  void _showStatusDialog(String taskDocId, TaskStatus currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('เปลี่ยนสถานะ', 'Change Status')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TaskStatus.values.map((status) {
              return ListTile(
                title: Text(status.name.toUpperCase()),
                leading: Radio<TaskStatus>(
                  value: status,
                  groupValue: currentStatus,
                  onChanged: (value) {
                    if (value != null) {
                      _updateTaskStatus(taskDocId, value.name);
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _updateTaskStatus(String taskDocId, String newStatus) async {
    if (widget.subjectId != null) {
      try {
        await FirestoreUserScope.taskDoc(
          _firestore,
          widget.subjectId!,
          taskDocId,
        ).update({'status': newStatus});
      } catch (e) {
        print('Error updating status: $e');
      }
    }
  }

  // ================= CONFIRM DELETE =================

  void confirmDelete(String taskDocId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(tr('ยืนยันการลบ', 'Confirm Delete')),
          content: Text(
            tr(
              'คุณแน่ใจหรือไม่ว่าต้องการลบงานนี้?\nการกระทำนี้ไม่สามารถย้อนกลับได้',
              'Are you sure you want to delete this task?\nThis action cannot be undone.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(tr('ยกเลิก', 'Cancel')),
            ),
            TextButton(
              onPressed: () async {
                if (widget.subjectId != null) {
                  await FirestoreUserScope.taskDoc(
                    _firestore,
                    widget.subjectId!,
                    taskDocId,
                  ).delete();
                }
                Navigator.pop(context);
              },
              child: Text(tr('ลบ', 'Delete'), style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ================= FORMAT DATE =================

  String formatDate(DateTime? date) {
    if (date == null) return tr('ไม่มีวันกำหนดส่ง', 'No due date');
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.subject.name),
            backgroundColor: Colors.pink,
          ),

          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.pink,
            onPressed: () => showTaskDialog(),
            child: const Icon(Icons.add),
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: FirestoreUserScope.tasks(
              _firestore,
              widget.subjectId!,
            ).snapshots(),
            builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final taskDocs = snapshot.data!.docs;

          if (taskDocs.isEmpty) {
            return Center(child: Text(tr('ยังไม่มีงาน', 'No tasks yet')));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: taskDocs.length,
            itemBuilder: (context, index) {
              final taskDocId = taskDocs[index].id;
              final taskData = taskDocs[index].data() as Map<String, dynamic>;
              final task = Task(
                title: taskData['title'] ?? '',
                description: taskData['description'] ?? '',
                dueDate: taskData['dueDate'] != null
                    ? (taskData['dueDate'] as Timestamp).toDate()
                    : null,
                status: _parseStatus(taskData['status'] ?? 'todo'),
              );

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.description.isEmpty ? "-" : task.description),
                      Text(
                        formatDate(task.dueDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  trailing: SizedBox(
                    width: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // สถานะและปุ่มเปลี่ยนสถานะ
                        GestureDetector(
                          onTap: () {
                            _showStatusDialog(taskDocId, task.status);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: task.status == TaskStatus.todo
                                  ? Colors.orange.shade200
                                  : task.status == TaskStatus.doing
                                  ? Colors.blue.shade200
                                  : Colors.green.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              task.status.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // ปุ่มลบ
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => confirmDelete(taskDocId),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailPage(
                          task: task,
                          subjectId: widget.subjectId,
                          taskDocId: taskDocId,
                        ),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                ),
              );
            },
          );
            },
          ),
        );
      },
    );
  }

  TaskStatus _parseStatus(String status) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => TaskStatus.todo,
    );
  }
}
