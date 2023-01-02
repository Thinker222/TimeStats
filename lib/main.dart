// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import './json_mgr.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:async';

void main() {
  runApp(const MyApp());
}

String text = "";

class StatList extends StatefulWidget {
  const StatList({super.key});
  @override
  State<StatList> createState() => _StatListState();
}

class _StatListState extends State<StatList> {
  List<Activity> data = List.empty();
  final Future<List<Activity>> _activities = getActivities();
  String groupValue = "Idle";
  String currentCategory = categories[0];
  int currentDayTime = dayTimes[(dayTimes.length / 2).floor()];
  int now = (DateTime.now().millisecondsSinceEpoch).round();
  Timer t = Timer(Duration(seconds: 1), () {});
  String pushValue = "";
  @override
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: ((context, snapshot) {
        if (snapshot.hasData) {
          if (data.isEmpty) {
            data = snapshot.data ?? List<Activity>.empty();
          }
          t.cancel();
          t = Timer(Duration(minutes: 1), () {
            if (groupValue != "Idle") {
              int val =
                  data.indexWhere((element) => element.name == groupValue);
              //data[val].totalTime += 60;
              data[val].totalTime -=
                  (data[val].entries.last.duration / 1000).round();
              data[val].entries.last.duration =
                  (DateTime.now().millisecondsSinceEpoch).round() -
                      data[val].entries.last.startTime;
              data[val].totalTime +=
                  (data[val].entries.last.duration / 1000).round();
              setState(() {});
              storeActivities(data);
            }
          });
          data.forEach(
              (element) => element.setTotalTimeForPastDays(currentDayTime));
          var stats = getFullStats(data, currentDayTime);
          return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 5,
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return activityHeader();
                        } else if (index == data.length + 1) {
                          return Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    onChanged: (newValue) {
                                      pushValue = newValue ?? "";
                                    },
                                  )),
                              DropdownButton(
                                  value: currentCategory,
                                  items: categories
                                      .map((e) => DropdownMenuItem<String>(
                                          value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) {
                                    currentCategory = val ?? categories[0];
                                    setState(() {});
                                  }),
                              Expanded(
                                  flex: 1,
                                  child: TextButton(
                                      child: Text("Add new item"),
                                      onPressed: () {
                                        if (pushValue != "" &&
                                            data
                                                .where((element) =>
                                                    element.name == pushValue)
                                                .isEmpty) {
                                          data.add(Activity(
                                              pushValue, currentCategory));
                                          setState(() {});
                                        }
                                      }))
                            ],
                          );
                        }

                        data.sort((a, b) {
                          if (a.name == "Idle") {
                            return -1;
                          }
                          if (b.name == "Idle") {
                            return 1;
                          }
                          if (a.totalTime < b.totalTime) {
                            return 1;
                          } else if (b.totalTime < a.totalTime) {
                            return -1;
                          } else {
                            return 0;
                          }
                        });
                        return activityToWidget(data[index - 1], () {
                          return Radio(
                            value: data[index - 1].name,
                            groupValue: groupValue,
                            onChanged: (value) {
                              groupValue = value ?? "";
                              now = (DateTime.now().millisecondsSinceEpoch)
                                  .round();
                              if (groupValue != "Idle") {
                                data[index - 1].addEntry(Entry(now, 0));
                              }
                              setState(() {});
                            },
                          );
                        }, stats);
                      },
                      itemCount:
                          data.length + 2, // 1 for header other for entry box
                    )),
                Expanded(
                  flex: 1,
                  child: Column(children: [
                    const Text("Past Days"),
                    DropdownButton(
                        value: currentDayTime,
                        items: dayTimes
                            .map((e) => DropdownMenuItem<int>(
                                value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: (val) {
                          currentDayTime = val ?? dayTimes[0];
                          setState(() {});
                        }),
                    Text("Total Time ${getTimeString(stats.totalTimeSpent)}"),
                    Text(
                        "Total Duration ${getTimeString(stats.totalDuration)}"),
                    Text(
                        "Percent of total duration ${stats.percentOfTotalDuration.toStringAsFixed(2)}%"),
                    Column(
                      children: stats.catStats.map((e) {
                        String val =
                            "${e.category}\nTotal time spent ${getTimeString(e.totalTimeSpent)}\nPercent of total time ${e.totalTimeSpentPercent.toStringAsFixed(2)}%";
                        return Text(
                          val,
                          textAlign: TextAlign.left,
                        );
                      }).toList(),
                    )
                  ]),
                )
                //Container(child: Text(stats.totalTimeSpent.toString())))
              ]);
        } else {
          return CircularProgressIndicator();
        }
      }),
      future: _activities,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final wordPair = WordPair.random();
    return MaterialApp(
      title: 'Time Stats',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Time Stats'),
        ),
        body: const Center(child: StatList()),
      ),
    );
  }
}
