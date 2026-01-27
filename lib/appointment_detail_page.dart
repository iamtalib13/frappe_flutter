import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Add Get for navigation
import 'package:dio/dio.dart'; // Add Dio for fetching updated data
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add for secure storage
import 'package:frappe_flutter/new_appointment_page.dart'; // Import new_appointment_page.dart
import 'package:frappe_flutter/models/appointment_model.dart';
import 'package:frappe_flutter/services/isar_service.dart';

class AppointmentDetailPage extends StatefulWidget {
  final String appointmentName;

  const AppointmentDetailPage({super.key, required this.appointmentName});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final IsarService _isarService = IsarService();
  Appointment? _appointmentDetails; // New, to store fetched details
  bool _isLoading = true; // New
  String _errorMessage = ''; // New

  @override
  void initState() {
    super.initState();
    _fetchAppointmentDetails(); // Fetch details to ensure they are up-to-date
  }

  Future<void> _fetchAppointmentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appointment = await _isarService.getAppointmentByName(widget.appointmentName);
      if (appointment != null) {
        setState(() {
          _appointmentDetails = appointment;
        });
      } else {
        _errorMessage = 'Failed to fetch appointment details';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching appointment details';
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
            : _appointmentDetails!.customerName),
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
                              _buildDetailRow('Customer', _appointmentDetails!.customerName),
                              _buildDetailRow('Scheduled Time', _appointmentDetails!.scheduledTime.toString()),
                              _buildDetailRow('Status', _appointmentDetails!.status),
                              _buildDetailRow('Last Modified', _appointmentDetails!.lastModified?.toString().split(' ')[0]),
                            ],
                          ),
                        ),
                      ),
                    ),
      floatingActionButton: _appointmentDetails != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (_appointmentDetails != null) {
                  final result = await Get.to(() => NewAppointmentPage(
                        initialAppointmentData: _appointmentDetails,
                        onAppointmentCreated:
                            () {}, // This is not used anymore, but it is required
                      ));
                  if (result == true) {
                    _fetchAppointmentDetails();
                  }
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
