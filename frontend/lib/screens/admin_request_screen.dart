import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';

class AdminRequestScreen extends StatefulWidget {
  const AdminRequestScreen({super.key});

  @override
  State<AdminRequestScreen> createState() => _AdminRequestScreenState();
}

class _AdminRequestScreenState extends State<AdminRequestScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRequests(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchRequests();
      }
    });
  }

  void _fetchRequests({bool refresh = false}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    if (authProvider.accessToken != null) {
      requestProvider.fetchAdminRequests(
        authProvider.accessToken!,
        refresh: refresh,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchRequests(refresh: true),
          ),
          PopupMenuButton<RequestStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              context.read<RequestProvider>().setStatusFilter(status);
              _fetchRequests(refresh: true);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Status')),
              ...RequestStatus.values.map(
                (s) => PopupMenuItem(value: s, child: Text(s.name)),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<RequestProvider>(
        builder: (context, provider, child) {
          if (provider.requests.isEmpty && provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.requests.isEmpty) {
            return const Center(child: Text('No requests found'));
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: provider.requests.length + (provider.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < provider.requests.length) {
                final request = provider.requests[index];
                return _buildRequestCard(request);
              } else {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    Color statusColor;
    switch (request.status) {
      case RequestStatus.PENDING:
        statusColor = Colors.orange;
        break;
      case RequestStatus.IN_PROGRESS:
        statusColor = Colors.blue;
        break;
      case RequestStatus.RESOLVED:
        statusColor = Colors.green;
        break;
      case RequestStatus.REJECTED:
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          request.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${request.userFullName}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                request.status.name,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Text(request.createdAt.toString().substring(0, 16)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(request.description),
                if (request.response != null) ...[
                  const Divider(),
                  const Text(
                    'Response:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(request.response!),
                  Text(
                    'At: ${request.responseAt.toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (request.status != RequestStatus.RESOLVED &&
                        request.status != RequestStatus.REJECTED)
                      ElevatedButton(
                        onPressed: () => _showUpdateStatusDialog(request),
                        child: const Text('Update Status'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(RequestModel request) {
    final TextEditingController responseController = TextEditingController(
      text: request.response,
    );
    RequestStatus selectedStatus = request.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<RequestStatus>(
                value: selectedStatus,
                isExpanded: true,
                onChanged: (val) => setState(() => selectedStatus = val!),
                items: RequestStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
              ),
              TextField(
                controller: responseController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Admin Response',
                  hintText: 'Enter your response here...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await context.read<RequestProvider>().updateRequestStatus(
                  authProvider.accessToken!,
                  request.id,
                  selectedStatus,
                  responseController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
