import 'dart:convert';
import 'dart:typed_data';

class FourByteString {
  final List<int> bytes;

  FourByteString(String string)
      : bytes = (string.length == 4) ? utf8.encode(string) : [0, 0, 0, 0];

  @override
  bool operator ==(Object other) =>
      other is FourByteString && bytes.toString() == other.bytes.toString();

  @override
  int get hashCode => bytes.hashCode;

  Uint8List encode() {
    return Uint8List.fromList(bytes);
  }
}

class ChunkTypes {
  static final audioDescription = FourByteString("desc");
  static final channelLayout = FourByteString("chan");
  static final information = FourByteString("info");
  static final audioData = FourByteString("data");
  static final packetTable = FourByteString("pakt");
  static final midi = FourByteString("midi");
}

class CafFile {
  final FileHeader fileHeader;
  final List<Chunk> chunks;

  CafFile({required this.fileHeader, required this.chunks});

  Uint8List encode() {
    final encodedFileHeader = fileHeader.encode();
    final encodedChunks = chunks.map((chunk) => chunk.encode()).toList();

    int totalLength = encodedFileHeader.length;
    for (var encodedChunk in encodedChunks) {
      totalLength += encodedChunk.length;
    }

    final data = Uint8List(totalLength);

    int offset = 0;
    data.setRange(offset, offset + encodedFileHeader.length, encodedFileHeader);
    offset += encodedFileHeader.length;

    for (var encodedChunk in encodedChunks) {
      data.setRange(offset, offset + encodedChunk.length, encodedChunk);
      offset += encodedChunk.length;
    }

    return data;
  }
}

class ChunkHeader {
  final FourByteString chunkType;
  final int chunkSize;

  ChunkHeader({required this.chunkType, required this.chunkSize});

  Uint8List encode() {
    final data = ByteData(12);

    final encodedChunkType = chunkType.encode();
    for (int i = 0; i < encodedChunkType.length; i++) {
      data.setUint8(i, encodedChunkType[i]);
    }

    data.setInt64(4, chunkSize);

    return data.buffer.asUint8List();
  }

  static ChunkHeader? decode(Uint8List data) {
    if (data.length < 12) return null;

    final chunkTypeData = data.sublist(0, 4);
    final chunkTypeString = utf8.decode(chunkTypeData);

    final chunkType = FourByteString(chunkTypeString);
    final chunkSize = ByteData.sublistView(data, 4, 12).getInt64(0);

    return ChunkHeader(chunkType: chunkType, chunkSize: chunkSize);
  }
}

class ChannelDescription {
  final int channelLabel;
  final int channelFlags;
  final List<double> coordinates;

  ChannelDescription({
    required this.channelLabel,
    required this.channelFlags,
    required this.coordinates,
  });

  Uint8List encode() {
    final data = ByteData(20);
    data.setInt32(0, channelLabel);
    data.setInt32(4, channelFlags);
    data.setFloat32(8, coordinates[0]);
    data.setFloat32(12, coordinates[1]);
    data.setFloat32(16, coordinates[2]);
    return data.buffer.asUint8List();
  }
}

class UnknownContents {
  final Uint8List data;

  UnknownContents(this.data);

  Uint8List encode() {
    return data;
  }
}

typedef Midi = Uint8List;

class Information {
  final String key;
  final String value;

  Information({required this.key, required this.value});

  Uint8List encode() {
    final encodedKey = utf8.encode(key);
    final encodedValue = utf8.encode(value);

    final totalLength = encodedKey.length + encodedValue.length;

    final data = Uint8List(totalLength);

    data.setRange(0, encodedKey.length, encodedKey);
    data.setRange(encodedKey.length, totalLength, encodedValue);

    return data;
  }
}

class PacketTableHeader {
  final int numberPackets;
  final int numberValidFrames;
  final int primingFrames;
  final int remainderFrames;

  PacketTableHeader({
    required this.numberPackets,
    required this.numberValidFrames,
    required this.primingFrames,
    required this.remainderFrames,
  });
}

class CAFStringsChunk {
  final int numEntries;
  final List<Information> strings;

  CAFStringsChunk({required this.numEntries, required this.strings});

  Uint8List encode() {
    int totalSize = 4;

    List<Uint8List> encodedStrings = [];
    for (var stringInfo in strings) {
      Uint8List encoded = stringInfo.encode();
      encodedStrings.add(encoded);
      totalSize += encoded.length;
    }

    final data = ByteData(totalSize);

    data.setUint32(0, numEntries);

    int offset = 4;
    for (Uint8List encodedString in encodedStrings) {
      for (int i = 0; i < encodedString.length; i++) {
        data.setUint8(offset, encodedString[i]);
        offset++;
      }
    }

    return data.buffer.asUint8List();
  }
}

class PacketTable {
  final PacketTableHeader header;
  final List<int> entries;

  PacketTable({required this.header, required this.entries});

  Uint8List encode() {
    final int dataSize = 24 + 2 * entries.length;
    final data = ByteData(dataSize);
    data.setInt64(0, header.numberPackets);
    data.setInt64(8, header.numberValidFrames);
    data.setInt32(16, header.primingFrames);
    data.setInt32(20, header.remainderFrames);

    int offset = 24;
    for (final entry in entries) {
      encodeVarint(offset, data, entry);
      offset += 2;
    }
    return data.buffer.asUint8List();
  }

  /// Encodes an integer to `data` using variable-length encoding technique (varint) format
  void encodeVarint(int offset, ByteData data, int i) {
    int position = offset;

    while (i >= 0x80) {
      data.setUint8(position++, (i & 0x7F) | 0x80);
      i >>= 7;
    }

    data.setUint8(position, i);
  }
}

class ChannelLayout {
  final int channelLayoutTag;
  final int channelBitmap;
  final int numberChannelDescriptions;
  final List<ChannelDescription> channels;

  ChannelLayout({
    required this.channelLayoutTag,
    required this.channelBitmap,
    required this.numberChannelDescriptions,
    required this.channels,
  });

  Uint8List encode() {
    final int dataSize = 12 + 20 * channels.length;
    final data = ByteData(dataSize);
    data.setInt32(0, channelLayoutTag);
    data.setInt32(4, channelBitmap);
    data.setInt32(8, numberChannelDescriptions);

    int offset = 12;
    for (final channel in channels) {
      final channelData = channel.encode();
      for (var i = 0; i < 20; i++) {
        data.setUint8(offset + i, channelData[i]);
      }
      offset += 20;
    }

    return data.buffer.asUint8List();
  }
}

class AudioData {
  final int editCount;
  final List<int> data;

  AudioData({required this.editCount, required this.data});

  Uint8List encode() {
    final result = ByteData(4 + data.length);
    result.setUint32(0, editCount);
    final uint8ListView = result.buffer.asUint8List();
    uint8ListView.setRange(4, 4 + data.length, data);

    return uint8ListView;
  }
}

class AudioFormat {
  final double sampleRate;
  final FourByteString formatID;
  final int formatFlags;
  final int bytesPerPacket;
  final int framesPerPacket;
  final int channelsPerPacket;
  final int bitsPerChannel;

  AudioFormat({
    required this.sampleRate,
    required this.formatID,
    required this.formatFlags,
    required this.bytesPerPacket,
    required this.framesPerPacket,
    required this.channelsPerPacket,
    required this.bitsPerChannel,
  });

  Uint8List encode() {
    final data = ByteData(32);
    data.setFloat64(0, sampleRate);
    data.buffer.asUint8List().setRange(8, 12, formatID.encode());
    data.setInt32(12, formatFlags);
    data.setInt32(16, bytesPerPacket);
    data.setInt32(20, framesPerPacket);
    data.setInt32(24, channelsPerPacket);
    data.setInt32(28, bitsPerChannel);
    return data.buffer.asUint8List();
  }
}

class Chunk {
  final ChunkHeader header;
  final dynamic contents;

  Chunk({required this.header, required this.contents});

  Uint8List encode() {
    // First, encode the header and temporarily store the result
    final encodedHeader = header.encode();

    Uint8List encodedContents;

    if (header.chunkType == ChunkTypes.audioDescription) {
      final audioFormat = contents as AudioFormat;
      encodedContents = audioFormat.encode();
    } else if (header.chunkType == ChunkTypes.channelLayout) {
      final channelLayout = contents as ChannelLayout;
      encodedContents = channelLayout.encode();
    } else if (header.chunkType == ChunkTypes.information) {
      final cafStringsChunk = contents as CAFStringsChunk;
      encodedContents = cafStringsChunk.encode();
    } else if (header.chunkType == ChunkTypes.audioData) {
      final dataX = contents as AudioData;
      encodedContents = dataX.encode();
    } else if (header.chunkType == ChunkTypes.packetTable) {
      final packetTable = contents as PacketTable;
      encodedContents = packetTable.encode();
    } else if (header.chunkType == ChunkTypes.midi) {
      final midi = contents as Midi;
      encodedContents = midi;
    } else {
      final unknownContents = contents as UnknownContents;
      encodedContents = unknownContents.encode();
    }

    final totalLength = encodedHeader.length + encodedContents.length;

    final data = Uint8List(totalLength);

    data.setRange(0, encodedHeader.length, encodedHeader);
    data.setRange(encodedHeader.length, totalLength, encodedContents);

    return data;
  }
}

class FileHeader {
  FourByteString fileType;
  int fileVersion;
  int fileFlags;

  FileHeader({
    required this.fileType,
    required this.fileVersion,
    required this.fileFlags,
  });

  void decode(Uint8List reader) {
    final data = ByteData.sublistView(reader);
    fileType =
        FourByteString(utf8.decode(data.buffer.asUint8List().sublist(0, 4)));
    fileVersion = data.getInt16(4);
    fileFlags = data.getInt16(6);
  }

  Uint8List encode() {
    final writer = ByteData(8);
    writer.buffer.asUint8List().setRange(0, 4, fileType.encode());
    writer.setInt16(4, fileVersion);
    writer.setInt16(6, fileFlags);
    return writer.buffer.asUint8List();
  }
}
