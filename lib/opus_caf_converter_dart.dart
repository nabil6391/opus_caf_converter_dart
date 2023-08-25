/// Library for converting Opus audio data to CAF format.
library opus_caf_converter;

import 'dart:io';

import 'src/caf_models.dart';
import 'src/opus_models.dart';

/// A class for converting Opus audio data to CAF format.
class OpusCaf {
  /// Converts Opus audio data to CAF format and saves it to the specified output path.
  ///
  /// [inputFile] is the path to the Opus audio file to be converted.
  /// [outputPath] is the path where the resulting CAF file will be saved.
  void convertOpusToCaf(String inputFile, String outputPath) {
    _convertOpusToCaf(inputFile, outputPath);
  }

  void _convertOpusToCaf(String inputFile, String outputPath) {
    final ogg = OggReader(inputFile);

    final header = ogg.readHeaders();

    final opusData = ogg.readOpusData();
    final audioData = opusData.audioData;
    final trailingData = opusData.trailingData;
    final frameSize = opusData.frameSize;

    final cf = _buildCafFile(
      header: header,
      audioData: audioData,
      trailingData: trailingData,
      frameSize: frameSize,
    );
    final encodedData = cf.encode();

    final file = File(outputPath);

    if (!file.existsSync()) {
      file.createSync();
    }

    file.writeAsBytesSync(encodedData);
  }

  /// Calculates the length of the packet table based on trailing data.
  int _calculatePacketTableLength(List<int> trailingData) {
    int packetTableLength = 24;

    for (var value in trailingData) {
      int numBytes = 0;
      if ((value & 0x7f) == value) {
        numBytes = 1;
      } else if ((value & 0x3fff) == value) {
        numBytes = 2;
      } else if ((value & 0x1fffff) == value) {
        numBytes = 3;
      } else if ((value & 0x0fffffff) == value) {
        numBytes = 4;
      } else {
        numBytes = 5;
      }
      packetTableLength += numBytes;
    }
    return packetTableLength;
  }

  /// Builds a CAF file from provided data.
  CafFile _buildCafFile(
      {required OggHeader header,
      required List<int> audioData,
      required List<int> trailingData,
      required int frameSize}) {
    final lenAudio = audioData.length;
    final packets = trailingData.length;
    final frames = frameSize * packets;

    final packetTableLength = _calculatePacketTableLength(trailingData);

    var cf = CafFile(
        fileHeader: FileHeader(
            fileType: FourByteString('caff'), fileVersion: 1, fileFlags: 0),
        chunks: []);

    final c = Chunk(
      header:
          ChunkHeader(chunkType: ChunkTypes.audioDescription, chunkSize: 32),
      contents: AudioFormat(
        sampleRate: 48000,
        formatID: FourByteString('opus'),
        formatFlags: 0x00000000,
        bytesPerPacket: 0,
        framesPerPacket: frameSize,
        channelsPerPacket: header.channels,
        bitsPerChannel: 0,
      ),
    );

    cf.chunks.add(c);

    final channelLayoutTag = (header.channels == 2) ? 6619138 : 6553601;

    final c1 = Chunk(
      header: ChunkHeader(
        chunkType: ChunkTypes.channelLayout,
        chunkSize: 12,
      ),
      contents: ChannelLayout(
        channelLayoutTag: channelLayoutTag,
        channelBitmap: 0x0,
        numberChannelDescriptions: 0,
        channels: [],
      ),
    );

    cf.chunks.add(c1);

    final c2 = Chunk(
      header: ChunkHeader(chunkType: ChunkTypes.information, chunkSize: 26),
      contents: CAFStringsChunk(
        numEntries: 1,
        strings: [Information(key: 'encoder\x00', value: 'Lavf59.27.100\x00')],
        // strings: [Information(key: 'encoder\x00', value: 'Lavf60.3.100\x00')],
      ),
    );

    cf.chunks.add(c2);

    final c3 = Chunk(
      header:
          ChunkHeader(chunkType: ChunkTypes.audioData, chunkSize: lenAudio + 4),
      contents: AudioData(editCount: 0, data: audioData),
    );

    cf.chunks.add(c3);

    final c4 = Chunk(
      header: ChunkHeader(
          chunkType: ChunkTypes.packetTable, chunkSize: packetTableLength),
      contents: PacketTable(
        header: PacketTableHeader(
          numberPackets: packets,
          numberValidFrames: frames,
          primingFrames: 0,
          remainderFrames: 0,
        ),
        entries: trailingData,
      ),
    );

    cf.chunks.add(c4);

    return cf;
  }
}
