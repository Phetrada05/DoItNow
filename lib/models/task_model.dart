enum TaskStatus { todo, doing, done }

class Task {
  String title;
  String description;
  DateTime? dueDate;
  TaskStatus status;

  Task({
    required this.title,
    this.description = "",
    this.dueDate,
    this.status = TaskStatus.todo,
  });

  bool get completed => status == TaskStatus.done;
}

class Subject {
  String name;
  List<Task> tasks;

  Subject({
    required this.name,
    required this.tasks,
  });
}