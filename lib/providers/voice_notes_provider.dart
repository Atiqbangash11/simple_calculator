import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../models/voice_note_model.dart';
import '../services/db_helper.dart';

class VoiceNotesProvider extends ChangeNotifier {
  final List<VoiceNote> _notes = [];
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  DateTime? _recordStartedAt;
  String? _pendingFilePath;

  List<VoiceNote> get notes => List.unmodifiable(_notes);
  bool get isRecording => _isRecording;
  Duration get recordDuration => _recordDuration;

  // True once a recording has been stopped but not yet saved or discarded -
  // i.e. it's sitting in the "review before saving" stage.
  bool get hasPendingRecording => _pendingFilePath != null && !_isRecording;

  Future<void> loadNotes() async {
    final fetched = await DBHelper.instance.fetchVoiceNotes();
    _notes
      ..clear()
      ..addAll(fetched);
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  List<VoiceNote> notesForDay(DateTime date) {
    return _notes
        .where((n) => n.createdAt.year == date.year && n.createdAt.month == date.month && n.createdAt.day == date.day)
        .toList();
  }

  List<VoiceNote> notesForMonth(DateTime month) {
    return _notes.where((n) => n.createdAt.year == month.year && n.createdAt.month == month.month).toList();
  }

  /// Starts recording. Returns null on success, or a human-readable error
  /// message (e.g. permission denied) that the UI can show in a SnackBar.
  Future<String?> startRecording() async {
    // Guard against a duplicate/overlapping recording session.
    if (_isRecording) return null;
    if (hasPendingRecording) {
      return 'Please save or discard the current recording first.';
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return 'Microphone permission was denied. Please allow microphone access in your phone settings to record voice notes.';
    }
    if (!await _recorder.hasPermission()) {
      return 'Microphone permission was denied. Please allow microphone access in your phone settings to record voice notes.';
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${dir.path}/voice_notes');
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }
      final filePath = '${voiceDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);

      _pendingFilePath = filePath;
      _recordStartedAt = DateTime.now();
      _recordDuration = Duration.zero;
      _isRecording = true;

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_recordStartedAt != null) {
          _recordDuration = DateTime.now().difference(_recordStartedAt!);
          notifyListeners();
        }
      });

      notifyListeners();
      return null;
    } catch (e) {
      _isRecording = false;
      return 'Could not start recording: $e';
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _recordTimer = null;
    await _recorder.stop();
    _isRecording = false;
    notifyListeners();
  }

  /// Deletes the just-stopped, not-yet-saved recording (e.g. user hit Discard).
  Future<void> discardPendingRecording() async {
    if (_pendingFilePath != null) {
      final file = File(_pendingFilePath!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // Best-effort cleanup - not fatal if this fails.
        }
      }
    }
    _pendingFilePath = null;
    _recordStartedAt = null;
    _recordDuration = Duration.zero;
    notifyListeners();
  }

  /// Persists the just-stopped recording's metadata + audio file locally.
  Future<void> savePendingRecording({String? title}) async {
    if (_pendingFilePath == null) return;

    final note = VoiceNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: (title == null || title.trim().isEmpty) ? 'Voice Note' : title.trim(),
      filePath: _pendingFilePath!,
      duration: _recordDuration,
      createdAt: _recordStartedAt ?? DateTime.now(),
    );

    await DBHelper.instance.insertVoiceNote(note);
    _notes.insert(0, note);

    _pendingFilePath = null;
    _recordStartedAt = null;
    _recordDuration = Duration.zero;
    notifyListeners();
  }

  Future<void> renameNote(VoiceNote note, String newTitle) async {
    final trimmed = newTitle.trim();
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;
    final updated = VoiceNote(
      id: note.id,
      title: trimmed.isEmpty ? 'Voice Note' : trimmed,
      filePath: note.filePath,
      duration: note.duration,
      createdAt: note.createdAt,
    );
    await DBHelper.instance.insertVoiceNote(updated); // same id -> REPLACE
    _notes[index] = updated;
    notifyListeners();
  }

  Future<void> deleteNote(VoiceNote note) async {
    await DBHelper.instance.deleteVoiceNote(note.id);
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();

    final file = File(note.filePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Metadata is already gone; a leftover file is not fatal.
      }
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
