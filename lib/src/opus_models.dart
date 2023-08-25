import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const pageHeaderTypeBeginningOfStream = 0x02;
const pageHeaderSignature = "OggS";
const idPageSignature = "OpusHead";

const pageHeaderLen = 27;
const idPagePayloadLength = 19;

enum OggReaderError {
  nilStream,
  badIDPageSignature,
  badIDPageType,
  badIDPageLength,
  badIDPagePayloadSignature,
  shortPageHeader,
}

class OggPageResult {
  final List<List<int>> segments;
  final OggPageHeader? pageHeader;
  final OggReaderError? error;

  OggPageResult({required this.segments, this.pageHeader, this.error});
}

class OpusData {
  final List<int> audioData;
  final List<int> trailingData;
  final int frameSize;

  OpusData(
      {required this.audioData,
      required this.trailingData,
      required this.frameSize});
}

// OggHeader is the metadata from the first two pages
// in the file (ID and Comment)
class OggHeader {
  late int channelMap;
  late int channels;
  late int outputGain;
  late int preSkip;
  late int sampleRate;
  late int version;

  OggHeader({
    required this.channelMap,
    required this.channels,
    required this.outputGain,
    required this.preSkip,
    required this.sampleRate,
    required this.version,
  });
}

// OggPageHeader is the metadata for a Page
// Pages are the fundamental unit of multiplexing in an Ogg stream
class OggPageHeader {
  late int granulePosition;
  late List<int> sig; // Dart uses List<int> for bytes.
  late int version;
  late int headerType;
  late int serial;
  late int index;
  late int segmentsCount;

  OggPageHeader({
    required this.granulePosition,
    required this.sig,
    required this.version,
    required this.headerType,
    required this.serial,
    required this.index,
    required this.segmentsCount,
  });
}

class OggReader {
  // You can use the File class to read contents.

  late String filePath; // Assuming you want to retain the file path.

  late RandomAccessFile? raFile;

  OggReader(String filePath) {
    var file = File(filePath);
    raFile = file.openSync(mode: FileMode.read);
  }

  Future<Future<Uint8List>?> readBytes(int byteCount) async {
    raFile?.setPositionSync(0);
    return raFile?.read(byteCount);
  }

  Future<String?>? readString(int byteCount) async {
    List<int>? bytes = (await readBytes(byteCount)) as List<int>?;
    return bytes != null ? utf8.decode(bytes) : null;
  }

  void close() {
    raFile?.close();
  }

  OggHeader readHeaders() {
    var result = parseNextPage();
    var segments = result.segments;
    var pageHeader = result.pageHeader;
    var err = result.error;

    if (err != null) {
      throw err;
    }

    if (pageHeader == null) {
      throw Exception(err);
    }

    if (utf8.decode(pageHeader.sig) != pageHeaderSignature) {
      throw OggReaderError.badIDPageSignature;
    }

    if (pageHeader.headerType != pageHeaderTypeBeginningOfStream) {
      throw OggReaderError.badIDPageType;
    }

    var header = OggHeader(
        channelMap: 0,
        channels: 0,
        outputGain: 0,
        preSkip: 0,
        sampleRate: 0,
        version: 0);

    if (segments[0].length != idPagePayloadLength) {
      throw OggReaderError.badIDPageLength;
    }

    if (utf8.decode(segments[0].sublist(0, 8)) != idPageSignature) {
      throw OggReaderError.badIDPagePayloadSignature;
    }

    header
      ..version = segments[0][8]
      ..channels = segments[0][9]
      ..preSkip = ByteData.sublistView(Uint8List.fromList(segments[0]), 10, 12)
          .getUint16(0, Endian.little)
      ..sampleRate =
          ByteData.sublistView(Uint8List.fromList(segments[0]), 12, 16)
              .getUint32(0, Endian.little)
      ..outputGain =
          ByteData.sublistView(Uint8List.fromList(segments[0]), 16, 18)
              .getUint16(0, Endian.little)
      ..channelMap = segments[0][18];

    return header;
  }

  OpusData readOpusData() {
    List<int> audioData = [];
    int frameSize = 0;
    List<int> trailingData = [];

    while (true) {
      var result = parseNextPage();
      List<List<int>> segments = result.segments;
      OggPageHeader? header = result.pageHeader;
      var err = result.error;

      if (err == OggReaderError.nilStream ||
          err == OggReaderError.shortPageHeader) {
        break;
      } else if (err != null) {
        throw Exception("Unexpected error: ${err.toString()}");
      }

      if (segments.isNotEmpty &&
          utf8.decode(segments.first.take(8).toList(), allowMalformed: true) ==
              "OpusTags") {
        continue;
      }

      for (var segment in segments) {
        trailingData.add(segment.length);
        audioData.addAll(segment);
      }

      if (header?.index == 2) {
        var tmpPacket = segments[0];
        if (tmpPacket.isNotEmpty) {
          var tmptoc = tmpPacket[0] & 255;
          var tocConfig = tmptoc >> 3;

          if (tocConfig < 12) {
            frameSize = 960 * (tocConfig & 3 + 1);
          } else if (tocConfig < 16) {
            frameSize = 480 << (tocConfig & 1);
          } else {
            frameSize = 120 << (tocConfig & 3);
          }
        }
      }
    }

    return OpusData(
        audioData: audioData, trailingData: trailingData, frameSize: frameSize);
  }

  OggPageResult parseNextPage() {
    var h = Uint8List(pageHeaderLen);

    var bytesRead = raFile?.readIntoSync(h) ?? 0;
    if (bytesRead < pageHeaderLen) {
      return OggPageResult(segments: [], error: OggReaderError.shortPageHeader);
    }

    OggPageHeader pageHeader = OggPageHeader(
      granulePosition: 0,
      sig: [],
      version: 0,
      headerType: 0,
      serial: 0,
      index: 0,
      segmentsCount: 0,
    );

    pageHeader
      ..sig = h.sublist(0, 4)
      ..version = h[4]
      ..headerType = h[5]
      ..granulePosition =
          ByteData.sublistView(h, 6, 14).getUint64(0, Endian.little)
      ..serial = ByteData.sublistView(h, 14, 18).getUint32(0, Endian.little)
      ..index = ByteData.sublistView(h, 18, 22).getUint32(0, Endian.little)
      ..segmentsCount = h[26];

    List<int> sizeBuffer = List<int>.filled(pageHeader.segmentsCount, 0);
    raFile?.readIntoSync(sizeBuffer);

    List<int> newArr = [];
    int i = 0;
    while (i < sizeBuffer.length) {
      if (sizeBuffer[i] == 255) {
        int sum = sizeBuffer[i];
        i++;
        while (i < sizeBuffer.length && sizeBuffer[i] == 255) {
          sum += sizeBuffer[i];
          i++;
        }
        if (i < sizeBuffer.length) {
          sum += sizeBuffer[i];
        }
        newArr.add(sum);
      } else {
        newArr.add(sizeBuffer[i]);
      }
      i++;
    }

    List<Uint8List> segments = [];

    for (int s in newArr) {
      List<int> segment = List<int>.filled(s, 0);
      raFile?.readIntoSync(segment);
      segments.add(Uint8List.fromList(segment));
    }

    return OggPageResult(segments: segments, pageHeader: pageHeader);
  }
}
