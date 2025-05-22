import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';

  // Stream controller for real-time text updates
  final StreamController<String> _textStreamController = StreamController<String>.broadcast();
  Stream<String> get textStream => _textStreamController.stream;

  // Stream controller for listening status updates
  final StreamController<bool> _listeningStatusController = StreamController<bool>.broadcast();
  Stream<bool> get listeningStatusStream => _listeningStatusController.stream;

  // Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onStatusChanged,
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          // Notify listeners about the error
          _isListening = false;
          _listeningStatusController.add(_isListening);
        },
        debugLogging: true,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      // Notify listeners about the error
      _isListening = false;
      _listeningStatusController.add(_isListening);
      return false;
    }
  }

  // Start listening for speech
  Future<bool> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Failed to initialize speech recognition');
        _isListening = false;
        _listeningStatusController.add(_isListening);
        return false;
      }
    }

    // Check if the speech recognition service is available
    bool available = false;
    try {
      available = await _speech.isAvailable;
    } catch (e) {
      debugPrint('Error checking speech recognition availability: $e');
      available = false;
    }

    if (!available) {
      debugPrint('Speech recognition is not available on this device');
      _isListening = false;
      _listeningStatusController.add(_isListening);
      return false;
    }

    // Reset the recognized text
    _recognizedText = '';
    _textStreamController.add(_recognizedText);

    try {
      bool success = false;
      try {
        success = await _speech.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 30), // Listen for up to 30 seconds
          pauseFor: const Duration(seconds: 3), // Auto-stop after 3 seconds of silence
          localeId: 'en_US', // Use English (US) as the default language
          cancelOnError: false,
        ) ?? false; // Handle null return by defaulting to false
      } catch (e) {
        debugPrint('Error in speech.listen: $e');
        success = false;
      }

      _isListening = success;
      _listeningStatusController.add(_isListening);
      return success;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      _listeningStatusController.add(_isListening);
      return false;
    }
  }

  // Stop listening for speech
  Future<void> stopListening() async {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
      _listeningStatusController.add(_isListening);
    }
  }

  // Cancel speech recognition
  Future<void> cancel() async {
    if (_isListening) {
      _speech.cancel();
      _isListening = false;
      _listeningStatusController.add(_isListening);
    }
  }

  // Get the current recognized text
  String getRecognizedText() {
    return _recognizedText;
  }

  // Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      final available = await _speech.isAvailable;
      return available ?? false; // Handle null return by defaulting to false
    } catch (e) {
      debugPrint('Error checking speech recognition availability: $e');
      return false;
    }
  }

  // Check if speech recognition is currently active
  bool isListening() {
    return _isListening;
  }

  // Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    _recognizedText = result.recognizedWords;
    _textStreamController.add(_recognizedText);

    // If we have a final result, log it
    if (result.finalResult) {
      debugPrint('Final speech recognition result: $_recognizedText');
    }
  }

  // Handle status changes
  void _onStatusChanged(String status) {
    debugPrint('Speech recognition status: $status');

    // Update listening status based on the status string
    if (status == 'listening') {
      _isListening = true;
    } else if (status == 'notListening' || status == 'done') {
      _isListening = false;
    }

    _listeningStatusController.add(_isListening);
  }

  // Dispose resources
  void dispose() {
    _textStreamController.close();
    _listeningStatusController.close();
    _speech.cancel();
  }
}
