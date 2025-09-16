import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:health/health.dart';
import 'dart:async';

void main() {
  runApp(const WalkieTalkie());
}

class WalkieTalkie extends StatefulWidget {
  const WalkieTalkie({Key? key}) : super(key: key);

  @override
  _WalkieTalkieState createState() => _WalkieTalkieState();
}

class _WalkieTalkieState extends State<WalkieTalkie> {
  int steps = 0;
  int baseSteps = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initHealthSteps();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _initHealthSteps(); //Calls for step count from Health API every 5 seconds
    });
  }

  /// Initializes step count by requesting today's total steps from the Health API.
  Future<void> _initHealthSteps() async {
    Health health = Health();
    health.configure();
    final types = [HealthDataType.STEPS];
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool requested = await health.requestAuthorization(types);
    if (requested) {
      try {
        // Fetch step count data points from midnight to now
        List<HealthDataPoint> data = await health.getHealthDataFromTypes(
          startTime: midnight,
          endTime: now,
          types: types,
        );
        data = health.removeDuplicates(data);
        if (data.isEmpty) {
          print("No health data returned");
        }
        // Sum all step counts retrieved
        int total = data.fold(0, (sum, d) {
          final value = d.value;
          if (value is NumericHealthValue) {
            return sum + value.numericValue.round();
          }
          return sum;
        });
        setState(() {
          baseSteps = total;
          steps = baseSteps; // initialize steps with today's total
        });
      } catch (e) {
        print("Health fetch error: $e");
      }
    } else {
      print("Health authorization not granted");
    }
  }

  ///example leaderboard
  final List<Map<String, dynamic>> leaderboard = [
    {'name': 'Sihyun', 'walkCount': 5000, 'isUser': false},
    {'name': 'Sibao', 'walkCount': 3000, 'isUser': false},
    {'name': 'Fubao', 'walkCount': 1000, 'isUser': false},
  ];

  @override
  Widget build(BuildContext context) {
    // Create a copy of the leaderboard and add the current user with live steps
    final updatedLeaderboard = List<Map<String, dynamic>>.from(leaderboard)
      ..add({'name': 'You', 'walkCount': steps, 'isUser': true});
    // Sort leaderboard descending by step count
    updatedLeaderboard.sort((a, b) => b['walkCount'].compareTo(a['walkCount']));

    return MaterialApp(
      theme: ThemeData.light().copyWith(primaryColor: Colors.green),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme, // don't override globally
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text(
            'Walkie Talkie',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Container for background image with blur effect and step count text overlay
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image
                    Image.asset("assets/background.jpg", fit: BoxFit.cover),
                    // Blur effect
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      // blur strength
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black.withOpacity(0),
                      ),
                    ),
                    // Step count
                    Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.height * 0.3 / 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'You have walked',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.black),
                          ),
                          Text(
                            '$steps steps',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Leaderboard section
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Daily Leaderboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Displays icons for top 3
                    for (int i = 0; i < updatedLeaderboard.length; i++) ...[
                      Builder(
                        builder: (context) {
                          String name = updatedLeaderboard[i]['name'];
                          int count = updatedLeaderboard[i]['walkCount'];
                          String prefix;
                          if (i == 0)
                            prefix = '🥇';
                          else if (i == 1)
                            prefix = '🥈';
                          else if (i == 2)
                            prefix = '🥉';
                          else
                            prefix = '';

                          bool isUser =
                              updatedLeaderboard[i]['isUser'] ?? false;
                          if (isUser) {
                            return Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: prefix),
                                  TextSpan(
                                    text: '$name - $count steps',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Text('$prefix$name - $count steps');
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}