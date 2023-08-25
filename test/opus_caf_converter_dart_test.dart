import 'dart:io';

import 'package:opus_caf_converter_dart/opus_caf_converter_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Test Opus Conversion', () {
    final opusCaf = OpusCaf();

    setUp(() {
      // Additional setup goes here.
    });

    test('Compare Output with FFMPEG CAF', () async {
      final inputFile = 'example/assets/sample4.opus';
      final outputFileCode = 'example/assets/sample4test.caf';
      final outputCorrect = 'example/assets/sample4.caf';

      await convertAndTestOutput(
          opusCaf, inputFile, outputFileCode, outputCorrect);
    });
  });
}

Future<void> convertAndTestOutput(OpusCaf opusCaf, String inputFile,
    String outputFileCode, String outputCorrect) async {
  opusCaf.convertOpusToCaf(inputFile, outputFileCode);
  print('Conversion complete from $inputFile to $outputFileCode');

  final contents1 = await File(outputCorrect).readAsBytes();
  final contents2 = await File(outputFileCode).readAsBytes();

  if (contents2.length != contents1.length) {
    print(
        'contents of input differ when decoding and reencoding, correct: ${contents1.length} wrong: ${contents2.length}');
    assert(false);
  } else {
    for (var i = 0; i < contents1.length; i++) {
      if (contents2[i] != contents1[i]) {
        print(
            'contents of output differ starting at offset $i ${contents1[i].toRadixString(16)} ${contents2[i].toRadixString(16)}');
        assert(false);
        break;
      }
    }
  }
  assert(true);
}
