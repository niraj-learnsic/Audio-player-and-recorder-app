import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  AudioPlayerScreenState createState() => AudioPlayerScreenState();
}

class AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _duration = const Duration();
  Duration _position = const Duration();

  // URL of the remote audio
  final String _audioUrl =
      'https://www2.cs.uic.edu/~i101/SoundFiles/BabyElephantWalk60.wav';
  // final String _audioUrl =
  //     'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Listen for player state changes (play, pause, stop)
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _isPaused = state == PlayerState.paused;
      });
    });

    // Listen for duration and position changes
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  @override
  dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Function to load and play audio from the remote URL
  Future<void> loadAudioFromURL() async {
    await _audioPlayer.play(UrlSource(_audioUrl));
    setState(() {
      _isPlaying = true;
    });
  }

  // Toggle play/pause
  void togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play(UrlSource(_audioUrl));
    }
  }

  // Seek to a new position when the slider is moved
  void seekToPosition(double value) {
    final newPosition = Duration(seconds: value.toInt());
    _audioPlayer.seek(newPosition);
    if (_isPaused) {
      _audioPlayer.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Audio Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const Text('Audio Player from Remote URL'),
            if (_isPlaying || _isPaused)
              Column(
                children: [
                  // Display current position and duration
                  Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble(),
                    onChanged: seekToPosition,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_position.toString().split('.').first),
                      Text(_duration.toString().split('.').first),
                    ],
                  ),
                  // Play/Pause button
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: togglePlayPause,
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: () => loadAudioFromURL(),
              child: const Text('Play Audio from URL'),
            ),
          ],
        ),
      ),
    );
  }
}
