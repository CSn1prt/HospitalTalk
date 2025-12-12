import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/conversation.dart';
import '../models/soap_note.dart';
import '../providers/conversation_provider.dart';
import '../services/database_helper.dart';
import 'soap_note_screen.dart';

class ConversationDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const ConversationDetailScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  bool _isPlaying = false;
  SoapNote? _existingSoapNote;

  @override
  void initState() {
    super.initState();
    _loadSoapNote();
  }

  Future<void> _loadSoapNote() async {
    if (widget.conversation.id != null) {
      final soapNote = await DatabaseHelper.instance
          .querySoapNoteByConversation(widget.conversation.id!);
      if (mounted) {
        setState(() {
          _existingSoapNote = soapNote;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy • HH:mm');
    final duration = widget.conversation.endTime != null
        ? widget.conversation.endTime!.difference(widget.conversation.startTime)
        : const Duration();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareConversation,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyToClipboard();
                  break;
                case 'soap':
                  _openSoapNote();
                  break;
                case 'delete':
                  _deleteConversation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copy Text'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'soap',
                child: Row(
                  children: [
                    const Icon(Icons.note_add, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(_existingSoapNote != null ? 'View SOAP Note' : 'Create SOAP Note'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.conversation.isCompleted 
                              ? Icons.check_circle 
                              : Icons.radio_button_unchecked,
                          color: widget.conversation.isCompleted 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.conversation.isCompleted 
                              ? 'Completed' 
                              : 'In Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.conversation.isCompleted 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.medical_services,
                      label: 'Doctor',
                      value: widget.conversation.doctorName,
                      iconColor: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.person,
                      label: 'Patient',
                      value: widget.conversation.patientName,
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Date & Time',
                      value: dateFormat.format(widget.conversation.startTime),
                      iconColor: Colors.orange,
                    ),
                    if (duration.inMinutes > 0) ...[
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.timer,
                        label: 'Duration',
                        value: _formatDuration(duration),
                        iconColor: Colors.purple,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.conversation.audioFilePath != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio Recording',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isPlaying ? _stopPlaying : _playRecording,
                            icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                            label: Text(_isPlaying ? 'Stop' : 'Play'),
                          ),
                          const SizedBox(width: 8),
                          if (_isPlaying)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_existingSoapNote != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'SOAP Note Available',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_existingSoapNote!.isFinalized)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Finalized',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Draft',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chief Complaint: ${_existingSoapNote!.chiefComplaint}',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _openSoapNote,
                        icon: const Icon(Icons.open_in_new),
                        label: Text(_existingSoapNote!.isFinalized ? 'View SOAP Note' : 'Edit SOAP Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transcription',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyToClipboard,
                          tooltip: 'Copy transcription',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        widget.conversation.transcription.isNotEmpty
                            ? widget.conversation.transcription
                            : 'No transcription available',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: widget.conversation.transcription.isNotEmpty
                              ? Colors.black
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _playRecording() async {
    if (widget.conversation.audioFilePath != null) {
      final provider = context.read<ConversationProvider>();
      await provider.playRecording(widget.conversation.audioFilePath!);
      setState(() {
        _isPlaying = true;
      });
      
      // Stop playing after some time (you might want to implement proper audio duration tracking)
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    }
  }

  void _stopPlaying() async {
    final provider = context.read<ConversationProvider>();
    await provider.stopPlaying();
    setState(() {
      _isPlaying = false;
    });
  }

  void _copyToClipboard() {
    if (widget.conversation.transcription.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.conversation.transcription));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transcription copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareConversation() {
    // You would implement actual sharing here using share_plus package
    _copyToClipboard();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation details copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.conversation.id != null) {
      final provider = context.read<ConversationProvider>();
      await provider.deleteConversation(widget.conversation.id!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _openSoapNote() async {
    if (widget.conversation.id == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SoapNoteScreen(
          conversation: widget.conversation,
          existingSoapNote: _existingSoapNote,
        ),
      ),
    );

    if (result == true) {
      _loadSoapNote();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}