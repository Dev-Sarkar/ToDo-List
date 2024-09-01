import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/profile.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';

class TaskScreen extends StatefulWidget {
  final Profile profile;
  final String? theme;

  TaskScreen({required this.profile, required this.theme});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  String? selectedTag;

  @override
  Widget build(BuildContext context) {
    //todo themes
    String? theme = widget.theme;

    final String backgroundImage;
    if (theme == 'Black & White') {
      backgroundImage = 'android/assets/images/white.jpg';
    } else if (theme == 'Neon') {
      backgroundImage = 'android/assets/images/The last.jpg';
    } else if (theme == 'Gold') {
      backgroundImage = 'android/assets/images/abstract.png';
    } else if (theme == 'Boho') {
      backgroundImage = 'android/assets/images/boho.jpg';
    } else if (theme == 'Glitter') {
      backgroundImage = 'android/assets/images/Cowboy.jpg';
    } else if (theme == 'Soft') {
      backgroundImage = 'android/assets/images/soft1.jpg';
    } else if (theme == 'Neutral') {
      backgroundImage = 'android/assets/images/nuetral.jpg';
    } else {
      backgroundImage = 'android/assets/images/pintrest.png'; // Fallback image
    }

    // Determine the app bar color based on selected theme
    final Color appBarColor;
    if (theme == 'Black & White') {
      appBarColor = Colors.black;
    } else if (theme == 'Neon') {
      appBarColor = Colors.purpleAccent;
    } else if (theme == 'Neutral') {
      appBarColor = Colors.brown;
    } else if (theme == 'Glitter') {
      appBarColor = Colors.redAccent;
    } else if (theme == 'Gold') {
      appBarColor = Colors.orange;
    } else if (theme == 'Soft') {
      appBarColor = Colors.grey;
    } else if (theme == 'Pastel') {
      appBarColor = Colors.lightGreenAccent;
    } else if (theme == 'Cute') {
      appBarColor = Colors.deepOrange;
    } else if (theme == 'Pink') {
      appBarColor = Colors.pink;
    } else {
      appBarColor = Colors.blueAccent; // Default app bar color
    }
    // todo themes
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tasks for ${widget.profile.name}',
        ),
        backgroundColor: appBarColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: appBarColor),
              child: Text(
                'Tags',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            StreamBuilder<List<String>>(
              stream: _firestoreService.getDistinctTags(widget.profile.id),
              builder: (context, snapshot) {
                List<String> tags = snapshot.data!;
                return Column(
                  children: tags.map((tag) {
                    return ListTile(
                      title: Text(tag),
                      onTap: () {
                        setState(() {
                          //selectedTag = tag;
                          selectedTag = tag == 'Show All' ? null : tag;
                        });

                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                );
              },
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          Column(children: [
            Expanded(
              child: StreamBuilder<List<Task>>(
                stream: selectedTag == null
                    ? _firestoreService.getTasksForProfile(widget.profile.id)
                    : _firestoreService.getTasksByTag(
                        widget.profile.id, selectedTag!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No tasks available.'));
                  }

                  final tasks = snapshot.data!;
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        tileColor: Colors.black.withOpacity(0.5),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: Colors.black,
                          ),
                        ),
                        leading: Checkbox(
                          value: task.completed,
                          onChanged: (bool? value) {
                            _toggleTaskCompletion(task);
                          },
                        ),
                        onTap: () => _editTask(task),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tag: ${task.tag}',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            if (task.dueDate != null)
                              Text(
                                //'Due Date: ${DateFormat.yMMMd().format(task.dueDate!.toDate())}')
                                'Due:  ${DateFormat('yMMMd').add_jm().format(task.dueDate!.toDate())}',
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              )
                            //'Selected Due Time: ${DateFormat('HH:mm').format(task.dueDate!.toDate())}}'),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Task input and button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addTask,
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _addTask() {
    if (_titleController.text.isNotEmpty) {
      final task = Task(
        id: '', // ID by Firestore.
        title: _titleController.text,
      );

      _firestoreService.addTaskToProfile(widget.profile.id, task).then((_) {
        _titleController.clear();
      });
    }
  }

  void _toggleTaskCompletion(Task task) async {
    if (!task.completed) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profile.id)
          .get();

      int currentXp = userDoc.get('xp') ?? 0;
      int currentLevel = userDoc.get('level') ?? 1;
      int xpForNextLevel = 100 + (currentLevel - 1) * 50;

      int xpGain = 20;
      currentXp += xpGain;

      if (currentXp >= xpForNextLevel) {
        currentLevel++;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profile.id)
          .update({
        'level': currentLevel,
        'xp': currentXp,
      });

      setState(() {});
    }

    final updatedTask = Task(
      id: task.id,
      title: task.title,
      tag: task.tag,
      dueDate: task.dueDate,
      completed: !task.completed,
    );

    _firestoreService.updateTask(widget.profile.id, updatedTask);
  }

  void scheduleNotification(Task task, DateTime scheduledTime) {
    NotificationService().scheduleNotification(
      task.id.hashCode,
      '${task.title} is due',
      'Tag: ${task.tag}',
      scheduledTime,
    );
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController =
            TextEditingController(text: task.title);
        final TextEditingController tagController =
            TextEditingController(text: task.tag);
        Timestamp? selectedDate = task.dueDate;

        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: tagController,
                decoration: InputDecoration(labelText: 'Tag'),
              ),
              TextButton(
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate?.toDate() ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    selectedDate = Timestamp.fromDate(pickedDate);
                  }
                },
                child: Text(
                    'Select Due Date: ${selectedDate != null ? DateFormat.yMMMd().format(selectedDate.toDate()) : 'None'}'),
              ),
              TextButton(
                onPressed: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime:
                          TimeOfDay.fromDateTime(selectedDate!.toDate()));
                  if (pickedTime != null) {
                    final DateTime updateDateTime = DateTime(
                      selectedDate!.toDate().year,
                      selectedDate!.toDate().month,
                      selectedDate!.toDate().day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    selectedDate = Timestamp.fromDate(updateDateTime);

                    scheduleNotification(task, updateDateTime);
                  }
                },
                child: Text(
                    'Select Due Time: ${selectedDate != null ? DateFormat("HH:mm").format(task.dueDate!.toDate()) : 'none'}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final updatedTask = Task(
                    id: task.id,
                    title: titleController.text,
                    tag: tagController.text.isNotEmpty
                        ? tagController.text
                        : 'Inbox',
                    dueDate: selectedDate,
                    completed: task.completed,
                  );
                  _firestoreService
                      .updateTask(widget.profile.id, updatedTask)
                      .then((_) {
                    Navigator.of(context).pop();
                  });
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                // Delete the task
                _firestoreService
                    .deleteTask(widget.profile.id, task.id)
                    .then((_) {
                  Navigator.of(context).pop();
                });
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
