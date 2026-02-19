import 'package:flutter/material.dart';

void main() {
  runApp(const DoItNowApp());
}

class DoItNowApp extends StatelessWidget {
  const DoItNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    int totalSubjects = 3;
    int pendingTasks = 5;

    final upcomingTasks = [
      "Math Assignment - Tomorrow",
      "Mobile Dev Project - Friday",
      "English Quiz - Monday"
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("DoItNow"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔹 Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryCard("Subjects", totalSubjects.toString()),
                _summaryCard("Pending Tasks", pendingTasks.toString()),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔹 Upcoming Tasks Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Upcoming Tasks",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔹 Task List
            Expanded(
              child: ListView.builder(
                itemCount: upcomingTasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment),
                      title: Text(upcomingTasks[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
