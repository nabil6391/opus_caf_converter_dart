import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opus_caf_converter_dart/opus_caf_converter_dart.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? textInfo;
  String? textConvertedUri;
  AudioPlayer player = AudioPlayer();

  Future<void> convertOpusToCaf() async {
    // Assuming you have the opus file in the assets folder.
    var tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;

    var outFile = '$tempPath/sample.caf';

    var opusCaf = OpusCaf();

    ByteData data = await rootBundle.load('assets/sample4.opus');
    List<int> bytes = data.buffer.asUint8List();

    // Create a new file in the temporary directory
    File file = File('$tempPath/sample4.opus');

    // Write bytes to the file
    await file.writeAsBytes(bytes);
    try {
      opusCaf.convertOpusToCaf('$tempPath/sample4.opus', outFile);
    } catch (error) {
      setState(() {
        textInfo = 'Error converting: $error';
      });
      return;
    }

    setState(() {
      textConvertedUri = outFile;
      textInfo = 'Successfully Converted'; // Set this after actual conversion
    });
  }

  Future<void> play() async {
    if (textConvertedUri != null) {
      try {
        await player.play(DeviceFileSource(textConvertedUri!));
      } catch (error) {
        setState(() {
          textInfo = 'Error playing: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OpusCAF Flutter Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (textInfo != null) Text(textInfo!),
            if (textConvertedUri != null) Text(textConvertedUri!),
            ElevatedButton(
              child: Text('Convert OPUS to CAF'),
              onPressed: convertOpusToCaf,
            ),
            ElevatedButton(
              child: Text('Play CAF'),
              onPressed: play,
            ),
          ],
        ),
      ),
    );
  }
}
