import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final String? subjectId;
  final String? taskDocId;

  const TaskDetailPage({
    super.key,
    required this.task,
    this.subjectId,
    this.taskDocId,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= DELETE =================
  void confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณแน่ใจหรือไม่ว่าต้องการลบงานนี้?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด dialog
              Navigator.pop(context); // กลับหน้า subject
            },
            child: const Text(
              "ลบ",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ================= EDIT =================
  void showEditDialog() {
    final titleController =
        TextEditingController(text: widget.task.title);
    final descController =
        TextEditingController(text: widget.task.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("แก้ไขงาน"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration:
                    const InputDecoration(labelText: "ชื่องาน"),
              ),
              TextField(
                controller: descController,
                decoration:
                    const InputDecoration(labelText: "รายละเอียด"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.task.title = titleController.text;
                widget.task.description =
                    descController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // ================= CHANGE DUE DATE =================

  Future<void> changeDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.task.dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // เลือกเวลา
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.task.dueDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          widget.task.dueDate = newDateTime;
        });

        // บันทึกไปที่ Firebase
        if (widget.subjectId != null && widget.taskDocId != null) {
          try {
            await _firestore
                .collection('subjects')
                .doc(widget.subjectId)
                .collection('tasks')
                .doc(widget.taskDocId)
                .update({'dueDate': newDateTime});
          } catch (e) {
            print('Error updating due date: $e');
          }
        }
      }
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.day}/${date.month}/${date.year}";
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

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดงาน"),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TITLE
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// STATUS BADGE
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: getStatusColor(task.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.status.name.toUpperCase(),
                style: TextStyle(
                  color: getStatusColor(task.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// DESCRIPTION
            const Text(
              "รายละเอียด",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(task.description.isEmpty ? "-" : task.description),

            const SizedBox(height: 25),

            /// DUE DATE
            const Text(
              "กำหนดส่ง",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.dueDate == null
                        ? "-"
                        : "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year} ${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}",
                  ),
                ),
                ElevatedButton(
                  onPressed: changeDate,
                  child: const Text("แก้ไข"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}