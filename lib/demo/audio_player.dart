// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';

// class AudioPlayerScreen extends StatelessWidget {
//   const AudioPlayerScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Audio Player')),
//         body: const AudioPlayerWidget(),
//       ),
//     );
//   }
// }

// class AudioPlayerWidget extends StatefulWidget {
//   const AudioPlayerWidget({super.key});

//   @override
//   _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
// }

// class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
//   final FlutterSoundPlayer _player = FlutterSoundPlayer();

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     await _player.openPlayer();
//   }

//   Future<void> playAudioFromUrl(String url) async {
//     try {
//       await _player.startPlayer(fromURI: url, codec: Codec.mp3);
//     } catch (e, s) {
//       log(e.toString());
//       log(s.toString());
//     }
//   }

//   Future<void> stopAudio() async {
//     await _player.stopPlayer();
//   }

//   @override
//   void dispose() {
//     _player.closePlayer();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         ElevatedButton(
//           onPressed: () => playAudioFromUrl(
//               'https://flutter-sound.canardoux.xyz/extract/05.mp3'),
//           child: const Text('Play Audio'),
//         ),
//         ElevatedButton(
//           onPressed: stopAudio,
//           child: const Text('Stop Audio'),
//         ),
//       ],
//     );
//   }
// }
