import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MetronomeApp());
}

class MetronomeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metronome',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MetronomeScreen(),
    );
  }
}

class MetronomeScreen extends StatefulWidget {
  @override
  _MetronomeScreenState createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  AudioPlayer player = AudioPlayer();

  late List<AudioPlayer> players;
  int currentPlayer = 0;
  // AudioPlayer player = AudioPlayer(
  //     audioLoadConfiguration: const AudioLoadConfiguration(
  //         androidLoadControl:
  //             AndroidLoadControl(targetBufferBytes: 1024 * 1024)));

  bool isPlaying = false;
  Timer timer = Timer(Duration.zero, () {});
  List<bool> beatStates = [false, false, false, false]; // 每小节拍子的闪烁状态
  int currentBeat = 0; // 当前到第几拍

  int bpm = 60; // beats per minute
  int beatsPerMeasure = 4; // 每小节的拍数，默认4拍
  int noteValue = 4; // 每拍的音符，默认4分音符
  List<(String, List<double>, List<bool>)> beats = [
    ('全音', [1.0], [true]),
    ('全音', [1.0], [true]),
    ('全音', [1.0], [true]),
    ('全音', [1.0], [true]),
  ];

  final List<(String, List<double>, List<bool>)> presetBeats = [
    ('全音', [1.0], [true]),
    ('平均8分', [0.5, 0.5], [true, true]),
    ('三连音', [0.33333, 0.33333, 0.33334], [true, true, true]),
    ('平均16分', [0.25, 0.25, 0.25, 0.25], [true, true, true, true]),
    ('前8后16', [0.5, 0.25, 0.25], [true, true, true]),
    ('前16后8', [0.25, 0.25, 0.5], [true, true, true]),
  ];

  startStop() async {
    if (isPlaying) {
      isPlaying = false;
      timer.cancel();
      setState(() {
        beatStates = List.filled(beatStates.length, false); // 停止时重置所有拍子的闪烁状态
      });
    } else {
      isPlaying = true;
      setState(() {
        beatStates = List.filled(beatsPerMeasure, false); // 根据每小节的拍数初始化拍子的闪烁状态
      });
      currentBeat = 0;
      await initPlayer();
      await playBeats();
    }
  }

  Future<void> playBeats() async {
    if (!isPlaying) {
      return;
    }

    (String, List<double>, List<bool>) beat = beats[currentBeat];
    await playNote(beat, 0);

    setState(() {
      beatStates = List.filled(beatsPerMeasure, false);
      beatStates[currentBeat] = true;
    });
    currentBeat = (currentBeat + 1) % beats.length;
  }

  Future<void> playNote(
      (String, List<double>, List<bool>) beat, int index) async {
    if (index == beat.$2.length - 1) {
      timer = Timer(
          Duration(milliseconds: (beat.$2[index] * (60000 / bpm)).toInt() - 1),
          () async {
        await playBeats();
      });
    } else {
      timer = Timer(
          Duration(milliseconds: (beat.$2[index] * (60000 / bpm)).toInt()),
          () async {
        await playNote(beat, index + 1);
      });
    }
    ;

    if (beat.$3[index]) {
      // await player.stop();
      // print("aaa: player stop cost: " +
      // (DateTime.now().millisecondsSinceEpoch - start).toString());
      // player.resume();
      var volume = index == 0 ? 1.0 : 0.3;

      playSound(volume);
    }
  }

  Future<void> initPlayer() async {
    AudioPlayer.global.setAudioContext(
      const AudioContext(
        android: AudioContextAndroid(
          audioMode: AndroidAudioMode.normal,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    List<AudioPlayer> l = [];
    for (int i = 0; i < 16; i++) {
      AudioPlayer p = AudioPlayer();
      // await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setSourceAsset('tick.wav');
      l.add(p);
      players = l;
    }
  }

  Future<void> resetPlayer(AudioPlayer p) async {
    // await p.setPlayerMode(PlayerMode.lowLatency);
    await p.setSourceAsset('tick.wav');
  }

  Future<void> playSound(double volume) async {
    // await player.setVolume(volume);

    var dateTime = DateTime.now();
    var start = dateTime.millisecondsSinceEpoch;

    print(
        "aaa: start play at ${dateTime.hour}:${dateTime.minute}:${dateTime.second}.${dateTime.millisecond}");

    var player = players[currentPlayer];
    currentPlayer = (currentPlayer + 1) % players.length;
    player
        .resume()
        .then((value) => print(
            "aaa: finish play cost: ${DateTime.now().millisecondsSinceEpoch - start}"))
        .then((_) async {
      // await player.stop();
      // await resetPlayer(player);
      // player.setSourceBytes(bytes)
    }).then((_) {
      var dateTime = DateTime.now();
      print(
          "aaa: finish stop at ${dateTime.hour}:${dateTime.minute}:${dateTime.second}.${dateTime.millisecond}");
      print("aaa: total cost: ${dateTime.millisecondsSinceEpoch - start}");
    });
  }

  // Future<void> initPlayer() async {
  //   await player.setAsset(// Load a URL
  //       'tick');
  //   await player.setAllowsExternalPlayback(true);
  // }

  // Future<void> playSound(double volume) async {
  //   await player.setVolume(volume);
  //   await player.play();
  // }

  void increaseBpm() {
    setState(() {
      bpm += 10;
    });
  }

  void decreaseBpm() {
    setState(() {
      bpm -= 10;
      if (bpm < 1) {
        bpm = 1;
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Metronome'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Container(
            //   height: 100,
            //   child: CustomPaint(
            //     painter: StaffPainter(
            //       beatStates: beatStates,
            //       beatsPerMeasure: beatsPerMeasure,
            //       noteValue: noteValue,
            //     ),
            //   ),
            // ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(beatStates.length, (index) {
                final state = beatStates[index];
                return GestureDetector(
                    onTap: () async {
                      final selectedRhythm =
                          await showDialog<(String, List<double>, List<bool>)>(
                        context: context,
                        builder: (BuildContext context) {
                          return EditRhythmDialog(
                              presetBeats: presetBeats,
                              selected: beats[index].$1);
                        },
                      );
                      if (selectedRhythm != null) {
                        setState(() {
                          beats[index] = selectedRhythm;
                        });
                      }
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: state ? Colors.lightBlue : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ));
              }).toList(),
            ),
            SizedBox(height: 20.0),
            Text(
              'BPM: $bpm',
              style: TextStyle(fontSize: 24.0),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      beatsPerMeasure = 10 -
                          (details.localPosition.dy / 20).clamp(1, 10).floor();
                      beatStates =
                          List.filled(beatsPerMeasure, false); // 更新拍子的闪烁状态
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    color: Colors.grey[300],
                    child: Text(
                      '$beatsPerMeasure',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ),
                SizedBox(width: 20.0),
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      noteValue =
                          64 >> ((details.localPosition.dy / 40).floor());
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    color: Colors.grey[300],
                    child: Text(
                      '$noteValue',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: decreaseBpm,
                  child: Icon(Icons.remove),
                ),
                SizedBox(width: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    await startStop();
                  },
                  child: isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
                ),
                SizedBox(width: 20.0),
                ElevatedButton(
                  onPressed: increaseBpm,
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StaffPainter extends CustomPainter {
  final List<bool> beatStates;
  final int beatsPerMeasure;
  final int noteValue;

  StaffPainter({
    required this.beatStates,
    required this.beatsPerMeasure,
    required this.noteValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    // Draw staff lines
    for (int i = 0; i < 5; i++) {
      double y = 30 + i * 10.0;
      canvas.drawLine(Offset(30, y), Offset(170, y), linePaint);
    }

    // Draw notes
    final textStyle = TextStyle(fontFamily: 'Akvo', fontSize: 15.0);
    final textSpans = [
      TextSpan(text: 'A', style: textStyle), // 1
      TextSpan(text: 'B', style: textStyle), // 2
      TextSpan(text: 'C', style: textStyle), // 4
      TextSpan(text: 'D', style: textStyle), // 8
      TextSpan(text: 'E', style: textStyle), // 16
      TextSpan(text: 'F', style: textStyle), // 32
      TextSpan(text: 'G', style: textStyle), // 64
    ];

    int totalBeats = beatsPerMeasure;
    double noteSpacing = (170 - 30) / totalBeats;

    for (int i = 0; i < totalBeats; i++) {
      TextPainter(
        text: textSpans[noteValue - 1],
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(canvas, Offset(30 + i * noteSpacing, 45)); // 在每小节的中间位置绘制音符
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class EditRhythmDialog extends StatefulWidget {
  final List<(String, List<double>, List<bool>)> presetBeats;
  String selected;

  EditRhythmDialog({required this.presetBeats, required this.selected});

  @override
  _EditRhythmDialogState createState() => _EditRhythmDialogState();
}

class _EditRhythmDialogState extends State<EditRhythmDialog> {
  late List<(String, List<double>, List<bool>)> rhythms;
  late String selectedRythm;

  @override
  void initState() {
    super.initState();
    rhythms = widget.presetBeats;
    selectedRythm = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('请选择节奏型'),
      content: Container(
        width: 300,
        height: 300,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 5.0,
            crossAxisSpacing: 5.0,
          ),
          itemCount: rhythms.length,
          itemBuilder: (BuildContext context, int index) {
            final rhythm = rhythms[index];
            final isSelected = rhythm.$1 == selectedRythm;
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop(rhythm);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color.fromARGB(255, 211, 231, 240)
                      : const Color.fromARGB(26, 236, 233, 233),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                alignment: Alignment.center,
                child: Text(rhythm.$1),
              ),
            );
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // TODO: Implement add new rhythm logic
          },
          child: Text('Add'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
