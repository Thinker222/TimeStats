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

class CategoryStat {
  String category;
  Color color;
  int totalTimeSpent;
  double totalTimeSpentPercent;

  CategoryStat(this.category, this.color, this.totalTimeSpent,
      this.totalTimeSpentPercent);
}

class FullStats {
  int totalTimeSpent;
  int totalDuration;
  double percentOfTotalDuration;
  List<CategoryStat> catStats;

  FullStats(this.totalTimeSpent, this.totalDuration,
      this.percentOfTotalDuration, this.catStats);
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

const List<int> dayTimes = [1, 2, 3, 7, 14, 21, 30, 60, 90];

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
  }

  void setTotalTimeForPastDays(int days) {
    totalTime = 0;
    totalTime = entries
        .where((entry) => DateTime.fromMillisecondsSinceEpoch(
                entry.startTime + entry.duration)
            .isAfter(DateTime.now().subtract(Duration(days: days))))
        .fold(0, (currentVal, element) {
      currentVal += (element.duration / 1000).round();
      return currentVal;
    });
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
        activity.setTotalTimeForPastDays(90);
      });

      list.add(activity);
    });
  } catch (e) {}

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
FullStats getFullStats(List<Activity> activities, int days) {
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
  if (DateTime.now()
      .subtract(Duration(days: days))
      .isAfter(DateTime.fromMillisecondsSinceEpoch(lowestTime))) {
    lowestTime =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
  }

  int totalDuration = ((maxTime - lowestTime) / 1000).round();

  double percentOfTotalDuration = ((totalTime / totalDuration) * 100);

  var categories = Set();
  categories
      .addAll(activities.where((e) => e.name != "Idle").map((e) => e.category));
  List<CategoryStat> catStats = categories.map(
    (e) {
      String category = e;
      int totalTimeCategory = activities
          .where((element) => element.category == category)
          .fold(
              0, (previousValue, element) => previousValue + element.totalTime);
      double percentOfTotalDuration = ((totalTimeCategory / totalTime) * 100);
      Color color = getColor(category);
      return CategoryStat(
          category, color, totalTimeCategory, percentOfTotalDuration);
    },
  ).toList();

  return FullStats(totalTime, totalDuration, percentOfTotalDuration, catStats);
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

String getTimeString(int totalTime) {
  int timeInHours = (totalTime / 3600).floor();
  int minutes = (totalTime / 60 % 60).floor();
  String minuteString = minutes.toString();
  if (minuteString.length == 1) {
    minuteString = "0" + minuteString;
  }
  String timeString = timeInHours.toString() + ":" + minuteString;
  return timeString;
}

Widget activityToWidget(
    Activity activity, Function generateRadioButton, FullStats stats) {
  // print(activity.name);
  // print(activity.totalTime);
  // print(stats.totalTimeSpent);
  // print("----");
  String timeSpent =
      (100 * activity.totalTime / stats.totalTimeSpent).toStringAsFixed(2);
  String timeDurationSpent =
      ((100 * activity.totalTime) / (stats.totalDuration)).toStringAsFixed(2);

  String timeString = getTimeString(activity.totalTime);

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
