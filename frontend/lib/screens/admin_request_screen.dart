import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../routes/app_routes.dart';

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

  Future<void> _selectTimeline(RequestModel request) async {
    final DateTime initialDate =
        request.solvedBy ?? DateTime.now().add(const Duration(days: 1));
    final DateTime firstDate = request.createdAt;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Set timeline to solve issue',
    );

    if (picked != null && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await context.read<RequestProvider>().setRequestTimeline(
          authProvider.accessToken!,
          request.id,
          picked,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timeline updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
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
      case RequestStatus.APPROVED:
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                if (request.solvedBy != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.timer, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${request.solvedBy.toString().substring(0, 10)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
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
                const SizedBox(height: 12),
                if (request.media.isNotEmpty) _buildMediaGallery(request.media),
                if (request.response != null) ...[
                  const Divider(),
                  Text(
                    'Admin Response (${request.adminName ?? "Admin"}):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Text(request.response!),
                  Text(
                    'At: ${request.responseAt.toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (request.status == RequestStatus.PENDING)
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          request.solvedBy == null
                              ? 'Set Timeline'
                              : 'Update Timeline',
                        ),
                        onPressed: () => _selectTimeline(request),
                      )
                    else
                      const SizedBox.shrink(),
                    if (request.status == RequestStatus.PENDING)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.reply),
                        label: const Text('Response'),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.requestDetailResponse,
                            arguments: request,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildMediaGallery(List<RequestMediaModel> mediaList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              final media = mediaList[index];
              return GestureDetector(
                onTap: () => _showFullScreenMedia(media),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: media.type == MediaType.IMAGE
                        ? Image.network(
                            media.url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error, color: Colors.red),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.videocam,
                                size: 40,
                                color: Colors.blueAccent,
                              ),
                              Positioned(
                                bottom: 4,
                                child: Text(
                                  'VIDEO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullScreenMedia(RequestMediaModel media) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: media.type == MediaType.IMAGE
                  ? Image.network(media.url, fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Video playback requires extra plugins',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            // Optional: Launch URL in browser
                          },
                          child: const Text('Open in Browser'),
                        ),
                      ],
                    ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
