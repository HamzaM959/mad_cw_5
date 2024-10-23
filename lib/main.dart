import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with TickerProviderStateMixin {
  List<Fish> fishList = [];
  String selectedFishEmoji = '🐟';
  double selectedSpeed = 1.0;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void updateSpeed(double newSpeed) {
    setState(() {
      selectedSpeed = newSpeed;
      for (Fish fish in fishList) {
        fish.updateSpeed(newSpeed);
      }
    });
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(
          emoji: selectedFishEmoji,
          speed: selectedSpeed,
          tickerProvider: this,
        ));
      });
    }
  }

  void _removeFish(int index) {
    setState(() {
      fishList.removeAt(index);
    });
  }

  void _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('fishCount', fishList.length);
    prefs.setDouble('fishSpeed', selectedSpeed);
    prefs.setString('selectedFish', selectedFishEmoji);
    print('Settings saved');
  }

  void _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      int fishCount = prefs.getInt('fishCount') ?? 0;
      selectedSpeed = prefs.getDouble('fishSpeed') ?? 1.0;
      selectedFishEmoji = prefs.getString('selectedFish') ?? '🐟';
      fishList = List.generate(fishCount, (index) {
        return Fish(
          emoji: selectedFishEmoji,
          speed: selectedSpeed,
          tickerProvider: this,
        );
      });
    });
    print('Settings loaded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.lightBlue[100],
            child: Stack(
              children: fishList.map((fish) {
                return fish.buildFish();
              }).toList(),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 10,
            right: 10,
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedFishEmoji,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFishEmoji = newValue!;
                    });
                  },
                  items: <String>['🐟', '🐠', '🐡', '🦈', '🐬']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Slider(
                  value: selectedSpeed,
                  min: 0.5,
                  max: 5.0,
                  onChanged: (value) {
                    updateSpeed(value); 
                  },
                  label: 'Fish Speed: ${selectedSpeed.toStringAsFixed(1)}',
                ),
                ElevatedButton(
                  onPressed: _addFish,
                  child: Text('Add Fish'),
                ),
                ElevatedButton(
                  onPressed: _savePreferences,
                  child: Text('Save Settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (Fish fish in fishList) {
      fish.dispose();
    }
    super.dispose();
  }
}

class Fish {
  final String emoji;
  double speed;
  late AnimationController _controller;
  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  final TickerProvider tickerProvider;
  final double maxMovement = 300; 

  Fish({
    required this.emoji,
    required this.speed,
    required this.tickerProvider,
  }) {
    _controller = AnimationController(
      duration: Duration(milliseconds: (5000 ~/ speed).toInt()),
      vsync: tickerProvider,
    );

    double startX = Random().nextDouble() * maxMovement;
    double startY = Random().nextDouble() * maxMovement;
    double endX = Random().nextDouble() * maxMovement;
    double endY = Random().nextDouble() * maxMovement;

    _xAnimation = Tween<double>(begin: startX, end: endX).animate(_controller);
    _yAnimation = Tween<double>(begin: startY, end: endY).animate(_controller);

    _controller.repeat(reverse: true); 
  }

  void updateSpeed(double newSpeed) {
    speed = newSpeed;
    _controller.duration = Duration(milliseconds: (5000 ~/ speed).toInt());
    _controller.forward(from: 0.0); 
  }

  Widget buildFish() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _xAnimation.value,
          top: _yAnimation.value,
          child: GestureDetector(
            onTap: () {
            },
            child: Text(
              emoji,
              style: TextStyle(fontSize: 30),
            ),
          ),
        );
      },
    );
  }

  void dispose() {
    _controller.dispose();
  }
}
