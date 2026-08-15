import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/voice_note_model.dart';
import '../providers/voice_notes_provider.dart';

// ==================== Voice Notes Screen ====================
// Same Day/Month filter pattern as the Sales Log screen, and the same
// Card + ListTile list style used throughout the rest of the app
// (see InventoryScreen / SalesScreen).
class VoiceNotesScreen extends StatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  State<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen> {
  bool _filterByDay = true; // true = Day filter, false = Month filter
  late DateTime _selectedDate;
  late DateTime _selectedMonth;

  final AudioPlayer _player = AudioPlayer();
  String? _playingNoteId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedMonth = DateTime.now();

    // Load persisted voice notes from local storage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VoiceNotesProvider>(context, listen: false).loadNotes();
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _playingNoteId = null; });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  List<VoiceNote> _getFilteredNotes(List<VoiceNote> allNotes) {
    if (_filterByDay) {
      return allNotes.where((n) {
        return n.createdAt.year == _selectedDate.year &&
            n.createdAt.month == _selectedDate.month &&
            n.createdAt.day == _selectedDate.day;
      }).toList();
    } else {
      return allNotes.where((n) {
        return n.createdAt.year == _selectedMonth.year && n.createdAt.month == _selectedMonth.month;
      }).toList();
    }
  }

  String _formatDateDisplay(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatMonthDisplay(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatNoteTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openMonthPicker() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month & Year'),
        content: SizedBox(
          width: 300,
          height: 250,
          child: Column(
            children: [
              const Text('Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final months = [
                      'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'
                    ];
                    final isSelected = _selectedMonth.month == index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, index + 1);
                        });
                      },
                      child: Container(
                        color: isSelected ? Colors.blueAccent.withAlpha(80) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text(months[index], style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final year = DateTime.now().year - 2 + index;
                    final isSelected = _selectedMonth.year == year;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(year, _selectedMonth.month);
                        });
                      },
                      child: Container(
                        color: isSelected ? Colors.blueAccent.withAlpha(80) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text('$year', style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  Future<void> _togglePlay(VoiceNote note) async {
    final file = File(note.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This recording file is missing on the device.')),
        );
      }
      return;
    }

    if (_playingNoteId == note.id && _isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    if (_playingNoteId == note.id && !_isPlaying) {
      await _player.resume();
      setState(() => _isPlaying = true);
      return;
    }

    await _player.stop();
    await _player.play(DeviceFileSource(note.filePath));
    setState(() {
      _playingNoteId = note.id;
      _isPlaying = true;
    });
  }

  Future<void> _confirmDelete(VoiceNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Note?'),
        content: Text('This will permanently delete "${note.title}". This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_playingNoteId == note.id) {
        await _player.stop();
        setState(() { _isPlaying = false; _playingNoteId = null; });
      }
      if (!mounted) return;
      await Provider.of<VoiceNotesProvider>(context, listen: false).deleteNote(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceProvider = context.watch<VoiceNotesProvider>();
    final filteredNotes = _getFilteredNotes(voiceProvider.notes);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter tabs
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Day'),
                  selected: _filterByDay,
                  onSelected: (selected) {
                    if (selected) setState(() => _filterByDay = true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Month'),
                  selected: !_filterByDay,
                  onSelected: (selected) {
                    if (selected) setState(() => _filterByDay = false);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date/Month selector
          if (_filterByDay)
            Card(
              color: Colors.blueAccent.withAlpha(35),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatDateDisplay(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openDatePicker,
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text('Change', style: TextStyle(fontSize: 12, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              color: Colors.blueAccent.withAlpha(35),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatMonthDisplay(_selectedMonth),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openMonthPicker,
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text('Change', style: TextStyle(fontSize: 12, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          Expanded(
            child: filteredNotes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No voice notes for this period.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      final isThisPlaying = _playingNoteId == note.id && _isPlaying;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent.withAlpha(35),
                            child: const Icon(Icons.graphic_eq, color: Colors.orangeAccent),
                          ),
                          title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${_formatDateDisplay(note.createdAt)} • ${_formatNoteTime(note.createdAt)}\n'
                            'Duration: ${_formatDuration(note.duration)}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: Colors.blueAccent,
                                  size: 30,
                                ),
                                onPressed: () => _togglePlay(note),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(note),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== Record Voice Note Bottom Sheet ====================
// Opened from the Voice Notes tab's FAB, matching the existing
// NewSaleBottomSheet's rounded-top bottom-sheet style.
class RecordVoiceNoteSheet extends StatefulWidget {
  const RecordVoiceNoteSheet({super.key});

  @override
  State<RecordVoiceNoteSheet> createState() => _RecordVoiceNoteSheetState();
}

class _RecordVoiceNoteSheetState extends State<RecordVoiceNoteSheet> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleRecordTap(VoiceNotesProvider provider) async {
    final error = await provider.startRecording();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoiceNotesProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Voice Note',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            enabled: !provider.isRecording,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Name (optional)',
              hintText: 'e.g. Ramesh Traders',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),

          if (!provider.isRecording && !provider.hasPendingRecording) ...[
            Center(
              child: GestureDetector(
                onTap: () => _handleRecordTap(provider),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.mic, color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: Text('Tap to record', style: TextStyle(color: Colors.grey))),
          ],

          if (provider.isRecording) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(provider.recordDuration),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Center(child: Text('Recording…', style: TextStyle(color: Colors.redAccent))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.stopRecording(),
              icon: const Icon(Icons.stop, color: Colors.white),
              label: const Text('Stop', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],

          if (provider.hasPendingRecording) ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Recorded: ${_formatDuration(provider.recordDuration)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await provider.discardPendingRecording();
                    },
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await provider.savePendingRecording(title: _nameController.text);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
