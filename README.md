# OpusCafConverterDart Package for Efficient Opus to CAF Conversion

OpusCAFCovnerter is a powerful dart package designed to seamlessly convert Opus files into Apple's Core Audio Format (CAF) files. Opus codec has swiftly taken center stage in the world of audio compression with its superior audio quality, lower latency, adaptability, and open-source, royalty-free nature.

But what truly makes Opus stand out? Here are the highlights:

- **High Audio Quality at Lower Bit Rates**: Remarkably, an Opus audio file compressed at 64kbps can deliver the same audio quality as an AAC file at 96kbps or an MP3 file at 128kbps. This means high-quality audio at a significantly smaller file size, leading to less bandwidth usage and storage needs.

- **Real-time Applications**: With its low latency design, Opus is an ideal choice for real-time applications like VoIP, video conferencing, and live streaming, where audio delay can significantly affect user experience.

- **Versatility**: Opus is highly versatile and adaptable, making it an excellent choice for both voice and music streaming across diverse network conditions and audio input types.

- **Open Source and Royalty-Free**: Opus' open-source and royalty-free nature eliminate the licensing costs and restrictions associated with other codecs like MP3 and AAC, offering significant advantages for developers and businesses.

Despite all these advantages, Opus is not natively supported in Apple's OS, leading to some compatibility challenges. However, there's a solution. Opus audio can be encapsulated within the CAF (Core Audio Format), an Apple-developed container format designed for the Core Audio framework.

This is where OpusCAF comes in, providing a smooth, easy-to-use solution for converting Opus files to CAF files. This conversion facilitates compatibility with Apple's Core Audio framework and other platforms that support CAF files, extending the reach of your Opus-encoded audio across a wider range of devices and applications.

The use of the Opus codec is gaining popularity in major platforms and applications worldwide. Here are some significant examples from wikipedia:

- **WhatsApp**: Since 2016, WhatsApp has been using the Opus audio file format, catering to billions of voice notes and calls made daily.

- **Signal**: Signal switched from Speex to the Opus audio codec in early 2017 for improved audio quality.

- **SoundCloud**: In 2018, SoundCloud transitioned from MP3 to Opus, reducing its required bandwidth for music streaming by half.

- **Vimeo**: Vimeo introduced the Opus audio format to its video platform in January 2021, enhancing audio quality for its user base.

- **Zetland**: The Danish journalism website Zetland switched from MP3 to Opus for its articles' audio recordings in 2021, achieving a 35% reduction in bandwidth and a reduced climate footprint.

With OpusCAF, you can now leverage the superior qualities of Opus while maintaining compatibility with Apple's audio frameworks. The future of audio is here with Opus and OpusCAF is your key to unlocking it.

## Usage

The function `convertOpusToCaf` takes two arguments:

- `inputFile` (String): The input file path of the Opus file that needs to be converted.
- `outputPath` (String): The output file path where the converted CAF file will be stored.

Example usage:

```swift
import 'package:opus_caf_converter_dart/opus_caf_converter_dart.dart';

var opusCaf = OpusCaf();

final inputFile = 'example/assets/sample4.opus';
final outputFileCode = 'example/assets/sample4test.caf';

opusCaf.convertOpusToCaf(inputFile, outputFileCode);
```

The function will read the Opus file from the specified input path, perform the conversion, and save the resulting CAF file at the defined output path.

## Implementation Details

The function `convertOpusToCaf` carries out the following steps:

1. Opens the input Opus file and initializes the Opus decoder.
2. Iterates through the Opus file, parsing each page, extracting audio data and frame sizes.
3. Creates a new CAF file with the right headers, chunks, and audio data.
4. Writes the CAF file to the specified output file path.

Please note that the provided script supports only mono and stereo audio channels. If your use case involves other channel configurations, you will have to modify the code accordingly.

## Dependencies

None

## Golang version

For developers interested in the Go language implementation, please visit the [GoLang version of Opus to CAF Converter](https://github.com/nabil6391/opus_caf_converter).

## Swift version

For developers interested in the swift language implementation for directly using, please visit the [Swift version of Opus to CAF Converter](https://github.com/nabil6391/opus_caf_converter_swift).