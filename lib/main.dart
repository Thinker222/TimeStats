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

class WordRow extends StatelessWidget {
  const WordRow(this.buttonTxt, this.phrase, this.foo);

  final String buttonTxt;
  final String phrase;
  final Function foo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(buttonTxt),
        TextButton(
            onPressed: () {
              text = phrase;
              foo();
            },
            child: Text(phrase))
      ],
    );

    //return Text("Hello");
    // return Expanded(child: Row(
    //   crossAxisAlignment: CrossAxisAlignment.stretch,
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     Expanded(
    //         child: ListTile(
    //       title: Text(phrase),
    //     )),
    //     Expanded(child: TextButton(onPressed: () => {}, child: Text(buttonTxt)))
    //   ],
    // ));
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({super.key});

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    final wordPair = WordPair.random();
    return Column(
      children: [
        Expanded(
            child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (context, i) {
            if (i.isOdd) return const Divider();
            final index = i ~/ 2;
            if (index >= _suggestions.length) {
              _suggestions.addAll((generateWordPairs().take(5)));
            }
            return WordRow(i.toString(), _suggestions[index].asPascalCase, () {
              setState(() {});
            });
          },
          itemCount: _suggestions.length < 50 ? 50 : _suggestions.length,
        )),
        Expanded(child: Text(text), flex: 0)
      ],
    );
  }
}

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
          FullStats stats = getFullStats(data);
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
                Expanded(flex: 1, child: Container())
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
