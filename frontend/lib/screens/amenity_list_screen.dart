import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần thêm package intl vào pubspec.yaml nếu chưa có
import '../models/service_model.dart';
import '../services/service_api.dart';

class AmenityListScreen extends StatefulWidget {
  const AmenityListScreen({Key? key}) : super(key: key);

  @override
  State<AmenityListScreen> createState() => _AmenityListScreenState();
}

class _AmenityListScreenState extends State<AmenityListScreen> {
  final ServiceApi _serviceApi = ServiceApi();
  late Future<List<ServiceModel>> _amenitiesFuture;

  @override
  void initState() {
    super.initState();
    _refreshAmenities();
  }

  void _refreshAmenities() {
    setState(() {
      _amenitiesFuture = _serviceApi.getAmenityServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: const Text('Tiện ích tòa nhà'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAmenities();
          await _amenitiesFuture;
        },
        child: FutureBuilder<List<ServiceModel>>(
          future: _amenitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Lỗi: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshAmenities,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Chưa có tiện ích nào.'));
            }

            final amenities = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: amenities.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = amenities[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.pool,
                      size: 40,
                      color: Colors.blue,
                    ), // Icon đại diện
                    title: Text(
                      item.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: item.description != null
                        ? Text(item.description!)
                        : null,
                    trailing: Text(
                      currencyFormat.format(item.unitPrice),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
