import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class StorageInfoWidget extends StatefulWidget {
  const StorageInfoWidget({Key? key}) : super(key: key);

  @override
  State<StorageInfoWidget> createState() => _StorageInfoWidgetState();
}

class _StorageInfoWidgetState extends State<StorageInfoWidget> {
  final StorageService _storageService = StorageService();
  StorageInfo? _storageInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storageInfo = await _storageService.getStorageInfo();
      setState(() {
        _storageInfo = storageInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  Color.fromARGB(255, 246, 246, 247),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text('Error loading storage info: $_error'),
                  ElevatedButton(
                    onPressed: _loadStorageInfo,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_storageInfo != null)
            _buildStorageInfo(_storageInfo!),
        ],
      ),
    );
  }

  Widget _buildStorageInfo(StorageInfo storageInfo) {
    return Column(
      children: [
        // Storage bars
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Storage Usage',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStorageBar(
                storageInfo.usedPercentage, storageInfo.freePercentage),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(Colors.blue, 'Used'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.green, 'Free'),
              ],
            ),
          ],
        ),

        const Divider(height: 24),


        
        _buildInfoRow('Total Storage:', storageInfo.formattedTotalSpace,
            valueColor: Colors.black),
        const SizedBox(height: 8),
        _buildInfoRow('Used Storage:', storageInfo.formattedUsedSpace,
            valueColor: Colors.red), 
        const SizedBox(height: 8),
        _buildInfoRow('Free Storage:', storageInfo.formattedFreeSpace,
            valueColor: Colors.green), 
        const SizedBox(height: 8),
        _buildInfoRow(
            'Usage:', '${storageInfo.usedPercentage.toStringAsFixed(1)}%',
            valueColor: Colors.black),
      ],
    );
  }

  Widget _buildStorageBar(double usedPercentage, double freePercentage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: usedPercentage / 100,
        backgroundColor: Colors.green.withOpacity(0.3),
        color: Colors.blue,
        minHeight: 24,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color valueColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor, // ✅ dynamic color
          ),
        ),
      ],
    );
  }
}
