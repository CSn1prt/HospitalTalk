import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/soap_note.dart';
import '../models/conversation.dart';
import '../providers/soap_note_provider.dart';
import '../services/database_helper.dart';
import 'soap_note_screen.dart';

class SoapNoteListScreen extends StatefulWidget {
  const SoapNoteListScreen({super.key});

  @override
  State<SoapNoteListScreen> createState() => _SoapNoteListScreenState();
}

class _SoapNoteListScreenState extends State<SoapNoteListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SoapNote> _filteredSoapNotes = [];
  bool _showOnlyFinalized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SoapNoteProvider>().loadSoapNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSoapNotes(List<SoapNote> allNotes) {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSoapNotes = allNotes.where((note) {
        final matchesSearch = query.isEmpty ||
            note.patientId.toLowerCase().contains(query) ||
            note.chiefComplaint.toLowerCase().contains(query) ||
            note.subjective.toLowerCase().contains(query) ||
            note.assessment.toLowerCase().contains(query);
        
        final matchesFilter = !_showOnlyFinalized || note.isFinalized;
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOAP Notes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  setState(() {
                    _showOnlyFinalized = !_showOnlyFinalized;
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(_showOnlyFinalized ? Icons.filter_list_off : Icons.filter_list),
                    const SizedBox(width: 8),
                    Text(_showOnlyFinalized ? 'Show All' : 'Show Finalized Only'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search SOAP notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final provider = context.read<SoapNoteProvider>();
                _filterSoapNotes(provider.soapNotes);
              },
            ),
          ),
          Expanded(
            child: Consumer<SoapNoteProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                _filterSoapNotes(provider.soapNotes);

                if (_filteredSoapNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.soapNotes.isEmpty 
                              ? 'No SOAP notes yet'
                              : 'No SOAP notes match your search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (provider.soapNotes.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'SOAP notes will appear here after creating them from conversations',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredSoapNotes.length,
                  itemBuilder: (context, index) {
                    final soapNote = _filteredSoapNotes[index];
                    return SoapNoteCard(
                      soapNote: soapNote,
                      onTap: () => _openSoapNote(soapNote),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openSoapNote(SoapNote soapNote) async {
    final conversation = await DatabaseHelper.instance
        .queryConversation(soapNote.conversationId);
    
    if (conversation != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SoapNoteScreen(
            conversation: conversation,
            existingSoapNote: soapNote,
          ),
        ),
      );
    }
  }
}

class SoapNoteCard extends StatelessWidget {
  final SoapNote soapNote;
  final VoidCallback onTap;

  const SoapNoteCard({
    super.key,
    required this.soapNote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          soapNote.patientId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dr. ${soapNote.createdBy}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: soapNote.isFinalized ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          soapNote.isFinalized ? 'Finalized' : 'Draft',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(soapNote.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (soapNote.chiefComplaint.isNotEmpty) ...[
                Text(
                  'Chief Complaint:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  soapNote.chiefComplaint,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              if (soapNote.assessment.isNotEmpty) ...[
                Text(
                  'Assessment:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  soapNote.assessment,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Created ${dateFormat.format(soapNote.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (soapNote.updatedAt != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.edit, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${dateFormat.format(soapNote.updatedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}