import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Add Get for navigation
import 'package:dio/dio.dart'; // Add Dio for fetching updated data
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add for secure storage
import 'package:frappe_flutter/new_appointment_page.dart'; // Import new_appointment_page.dart

class AppointmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final Dio _dio = Dio(); // New
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(); // New
  Map<String, dynamic>? _appointmentDetails; // New, to store fetched details
  bool _isLoading = true; // New
  String _errorMessage = ''; // New

  @override
  void initState() {
    super.initState();
    _appointmentDetails = widget.appointment; // Initialize with passed data
    _fetchAppointmentDetails(); // Fetch details to ensure they are up-to-date
  }

  Future<void> _fetchAppointmentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) {
        Get.snackbar('Error', 'Session expired. Please log in again.');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired.';
        });
        return;
      }

      final response = await _dio.get(
        'https://mysahayog.com/api/resource/Appointment/${_appointmentDetails!['name']}',
        options: Options(
          headers: {'Cookie': 'sid=$sid'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _appointmentDetails = response.data['data'];
        });
      } else {
        _errorMessage = 'Failed to fetch appointment details: ${response.statusCode}';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'An error occurred while fetching appointment details';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading || _appointmentDetails == null
            ? 'Appointment Details'
            : _appointmentDetails!['customer_name'] ?? 'Appointment Details'),
        backgroundColor: const Color(0xFF006767),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _appointmentDetails == null
                  ? const Center(child: Text('Appointment details not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Customer', _appointmentDetails!['customer_name']),
                              _buildDetailRow('Scheduled Time', _appointmentDetails!['scheduled_time']),
                              _buildDetailRow('Status', _appointmentDetails!['status']),
                              _buildDetailRow('Last Modified', _appointmentDetails!['modified']?.split(' ')[0]),
                            ],
                          ),
                        ),
                      ),
                    ),
      floatingActionButton: _appointmentDetails != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (_appointmentDetails != null) {
                  await Get.to(() => NewAppointmentPage(
                    initialAppointmentData: _appointmentDetails!,
                    onAppointmentCreated: _fetchAppointmentDetails, // Use _fetchAppointmentDetails as callback
                  ));
                  _fetchAppointmentDetails(); // Refresh details after returning
                }
              },
              label: const Text('Update Appointment'),
              icon: const Icon(Icons.edit),
              backgroundColor: const Color(0xFF006767),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}
