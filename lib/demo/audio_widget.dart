import 'dart:async';
import 'dart:developer';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

enum PlayerState { isPlaying, isPaused, isStopped, init, isLoading, isError }

const int tSTREAMSAMPLERATE = 44000;

class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;
  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late FlutterSoundPlayer _audioPlayer;
  ValueNotifier<PlayerState> playerState = ValueNotifier(PlayerState.init);

  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _duration = ValueNotifier(Duration.zero);
  // String _playerTxt = '00:00:00';
  // bool _isSliderDragging = false;

  // URL of the remote audio
  // final String _audioUrl = 'assets/samples/sample.pcm';

  setPlayerState(PlayerState value) {
    playerState.value = value;
  }

  setPositionState(Duration value) {
    _position.value = value;
  }

  setDurationState(Duration value) {
    _duration.value = value;
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = FlutterSoundPlayer();

    // Initialize the player
    _initializePlayer();
  }

  // Initialize the audio player
  Future<void> _initializePlayer() async {
    // log(widget.audioUrl);
    await _audioPlayer.closePlayer();
    await _audioPlayer.openPlayer();
    await _audioPlayer
        .setSubscriptionDuration(const Duration(milliseconds: 10));
  }

  Future<void> stopPlayer() async {
    try {
      await _audioPlayer.stopPlayer();
      _audioPlayer.logger.d('stopPlayer');
      if (_playerSubscription != null) {
        await _playerSubscription!.cancel();
        _playerSubscription = null;
      }
      setPositionState(Duration.zero);
    } on Exception catch (err) {
      _audioPlayer.logger.d('error: $err');
    }
    _audioPlayer.logger.d('Play finished');
    setPositionState(Duration.zero);
    setPlayerState(PlayerState.isStopped);
  }

  StreamSubscription? _playerSubscription;

  void _addListeners() {
    cancelPlayerSubscriptions();
    _playerSubscription = _audioPlayer.onProgress!.listen((e) {
      setDurationState(e.duration);
      // if (_duration <= Duration.zero) _duration = Duration.zero;
      setPositionState(e.position);
      // if (_position < Duration.zero) _position = Duration.zero;
    });
  }

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription!.cancel();
      _playerSubscription = null;
    }
  }

  @override
  dispose() {
    _audioPlayer.closePlayer();
    super.dispose();
  }

  // Function to load and play audio from the remote URL
  Future<void> loadAudioFromURL() async {
    setPlayerState(PlayerState.isLoading);
    try {
      await _audioPlayer.startPlayer(
          fromURI: widget.audioUrl,
          sampleRate: tSTREAMSAMPLERATE,
          // codec: Codec.pcm16WAV,
          whenFinished: () {
            // stopPlayer();
            _audioPlayer.logger.d('Play finished');
            setPlayerState(PlayerState.isStopped);
            setPositionState(Duration.zero);
            seekToPosition(Duration.zero);
          });
      _addListeners();
      setPlayerState(PlayerState.isPlaying);
    } catch (e) {
      log(e.toString());
      setPlayerState(PlayerState.isError);
    }
  }

  // Toggle play/pause
  void togglePlayPause() async {
    switch (playerState.value) {
      case PlayerState.isPlaying:
        _audioPlayer.pausePlayer();
        setPlayerState(PlayerState.isPaused);
        break;
      case PlayerState.isPaused || PlayerState.isStopped:
        _audioPlayer.resumePlayer();
        setPlayerState(PlayerState.isPlaying);
        break;
      case PlayerState.init:
        loadAudioFromURL();
        break;
      default:
    }
  }

  // Seek to a new position when the slider is moved
  void seekToPosition(Duration value) async {
    _audioPlayer.seekToPlayer(value);
    setPositionState(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: Listenable.merge([playerState, _duration, _position]),
        builder: (_, __) {
          return playerState.value == PlayerState.isError
              ? Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        loadAudioFromURL();
                      },
                      icon: const Icon(
                        Icons.replay,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Error playing audio",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: playerState.value == PlayerState.isLoading
                          ? const SizedBox(
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator())
                          : Icon(
                              playerState.value == PlayerState.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 32,
                              color: widget.audioUrl == null
                                  ? Colors.grey.shade400
                                  : Colors.black,
                            ),
                      onPressed: (widget.audioUrl == null ||
                              playerState.value == PlayerState.isLoading)
                          ? null
                          : togglePlayPause,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ProgressBar(
                        progress: _position.value,
                        barCapShape: BarCapShape.round,
                        total: _duration.value,
                        onSeek: (duration) {
                          if (_duration.value == Duration.zero) {
                            togglePlayPause();
                            return;
                          }
                          seekToPosition(duration);
                        },
                      ),
                    ),
                  ],
                );
        });
  }
}
