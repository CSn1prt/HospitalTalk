import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/conversation_provider.dart';
import '../models/conversation.dart';
import 'conversation_detail_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final _searchController = TextEditingController();
  List<Conversation> _filteredConversations = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadConversations() {
    final provider = context.read<ConversationProvider>();
    provider.loadConversations();
    _filteredConversations = provider.conversations;
  }

  void _searchConversations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredConversations = context.read<ConversationProvider>().conversations;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final provider = context.read<ConversationProvider>();
    final results = await provider.searchConversations(query);
    
    setState(() {
      _filteredConversations = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchConversations('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchConversations,
            ),
          ),
          Expanded(
            child: Consumer<ConversationProvider>(
              builder: (context, provider, child) {
                if (_isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_filteredConversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No conversations found'
                              : 'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Try a different search term'
                              : 'Start recording your first conversation',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadConversations();
                  },
                  child: ListView.builder(
                    itemCount: _filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _filteredConversations[index];
                      return _ConversationCard(
                        conversation: conversation,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationDetailScreen(
                                conversation: conversation,
                              ),
                            ),
                          );
                        },
                        onDelete: () => _deleteConversation(conversation),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _deleteConversation(Conversation conversation) async {
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

    if (confirmed == true && conversation.id != null) {
      final provider = context.read<ConversationProvider>();
      await provider.deleteConversation(conversation.id!);
      _loadConversations();
    }
  }
}

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationCard({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final duration = conversation.endTime != null
        ? conversation.endTime!.difference(conversation.startTime)
        : const Duration();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: conversation.isCompleted ? Colors.green : Colors.orange,
          child: Icon(
            conversation.isCompleted ? Icons.check : Icons.mic,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Dr. ${conversation.doctorName} • ${conversation.patientName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(conversation.startTime)),
            if (conversation.transcription.isNotEmpty)
              Text(
                conversation.transcription.length > 100
                    ? '${conversation.transcription.substring(0, 100)}...'
                    : conversation.transcription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (duration.inMinutes > 0)
              Text(
                '${duration.inMinutes}m',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
        isThreeLine: conversation.transcription.isNotEmpty,
      ),
    );
  }
}