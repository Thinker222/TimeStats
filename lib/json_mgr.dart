import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;

const int OLD_LIMIT = 90 * 24 * 60 * 60;
const String ACTIVITIES = "Activities";
const String ENTRIES = "Entries";
const String NAME = "Name";
const String CATEGORY = "Category";

class FullStats {
  int totalTimeSpent;
  int totalDuration;

  FullStats(this.totalTimeSpent, this.totalDuration);
}

class Entry {
  int startTime = 0;
  int duration = 0;
  Entry(this.startTime, this.duration);
}

const List<String> categories = [
  "games",
  "social",
  "entertainment",
  "shopping",
  "school",
  "projects",
  "learning",
];

List<Color> colors = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.yellow,
  Colors.purple,
  Colors.pink
];

Color getColor(String str) {
  int index = categories.indexOf(str);
  Color color;
  if (index < 0 || index >= colors.length) {
    color = Colors.black;
  } else {
    color = colors[index];
  }
  color = Color.fromARGB(200, color.red, color.green, color.blue);
  return color;
}

class Activity {
  String name;
  String category;
  int totalTime = 0;
  List<Entry> entries = List.empty(growable: true);
  Activity(this.name, this.category);

  void addEntry(Entry entr) {
    entries.add(entr);
    totalTime += (entr.duration / 1000).round();
  }
}

Future<List<Activity>> getActivities() async {
  List<Activity> list = List<Activity>.empty(growable: true);
  try {
    final directory = await getApplicationDocumentsDirectory();
    String dir = directory.path;
    File f = File('$dir/time_stats.json');
    final contents = await f.readAsString();
    var dat = jsonDecode(contents);
    var activities = dat[ACTIVITIES];
    activities.forEach((var act) {
      Activity activity = Activity(act[NAME], act[CATEGORY]);
      act[ENTRIES].forEach((var entry) {
        if (DateTime.fromMillisecondsSinceEpoch(entry[0] + entry[1])
            .isAfter(DateTime.now().subtract(Duration(days: 90)))) {
          activity.addEntry(Entry(entry[0], entry[1]));
        }
      });

      list.add(activity);
    });
  } catch (e) {
    // list.add(Activity("Minecraft", "games"));
    // list.add(Activity("Youtube", "entertainment"));
    // list.add(Activity("Rust Book", "learning"));
  }

  list.insert(0, Activity("Idle", ""));
  return list;
}

void storeActivities(List<Activity> activities) async {
  var activityDictionary = {ACTIVITIES: []};
  activities.forEach((var element) {
    var currentActivityDictionary = {};
    currentActivityDictionary[NAME] = element.name;
    currentActivityDictionary[CATEGORY] = element.category;
    currentActivityDictionary[ENTRIES] = [];
    element.entries.forEach((var element2) {
      currentActivityDictionary[ENTRIES]
          .add([element2.startTime, element2.duration]);
    });
    if (!currentActivityDictionary[ENTRIES].isEmpty) {
      activityDictionary[ACTIVITIES]?.add(currentActivityDictionary);
    }
  });

  final directory = await getApplicationDocumentsDirectory();
  String dir = directory.path;
  File f = await File('$dir/time_stats.json').create();
  String data = jsonEncode(activityDictionary);
  f.writeAsString(data);
}

// Fix before epoch ends
FullStats getFullStats(List<Activity> activities) {
  int totalTime = activities.fold(
      0, (previousValue, element) => previousValue + element.totalTime);
  int lowestTime = activities.fold(
      DateTime.now().millisecondsSinceEpoch,
      (previousValue, element) => min(
          previousValue,
          element.entries.fold(
              DateTime.now().millisecondsSinceEpoch,
              (previousValue, element) =>
                  min(previousValue, element.startTime))));
  int maxTime = activities.fold(
      0,
      (previousValue, element) => max(
          previousValue,
          element.entries.fold(
              0,
              (previousValue, element) =>
                  max(previousValue, element.startTime + element.duration))));
  if (totalTime == 0) {
    totalTime = 1;
  }
  if (maxTime <= lowestTime) {
    maxTime = 1;
    lowestTime = 0;
  }

  return FullStats(totalTime, maxTime - lowestTime);
}

Widget getTextBox(String text) {
  return Expanded(
    flex: 1,
    child: Text(
      text,
      style: TextStyle(fontSize: 20),
    ),
  );
}

Widget activityHeader() {
  return Container(
      color: Colors.amber,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          getTextBox("Activity Name"),
          getTextBox("Time used"),
          getTextBox('% time of computer time'),
          getTextBox('% time of general time'),
        ],
      ));
}

Widget activityToWidget(
    Activity activity, Function generateRadioButton, FullStats stats) {
  String timeSpent =
      (100 * activity.totalTime / stats.totalTimeSpent).toStringAsFixed(2);
  String timeDurationSpent =
      (100 * activity.totalTime / (stats.totalDuration / 1000))
          .toStringAsFixed(2);
  int timeInHours = (activity.totalTime / 3600).round();
  int minutes = (activity.totalTime / 60).round();
  String minuteString = minutes.toString();
  if (minuteString.length == 1) {
    minuteString = "0" + minuteString;
  }
  String timeString = timeInHours.toString() + ":" + minuteString;

  return Container(
      decoration: BoxDecoration(
          border: Border.all(), color: getColor(activity.category)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          getTextBox(activity.name),
          getTextBox(timeString),
          getTextBox('$timeSpent %'),
          getTextBox('$timeDurationSpent %'),
          generateRadioButton()
        ],
      ));
}
