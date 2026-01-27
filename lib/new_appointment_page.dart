// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:frappe_flutter/error_page.dart';
import 'package:frappe_flutter/models/appointment_model.dart';
import 'package:frappe_flutter/models/sync_status.dart';
import 'package:frappe_flutter/services/isar_service.dart';

class NewAppointmentPage extends StatefulWidget {
  final VoidCallback? onAppointmentCreated;
  final Appointment? initialAppointmentData;

  const NewAppointmentPage({
    super.key,
    this.onAppointmentCreated,
    this.initialAppointmentData,
  });

  @override
  State<NewAppointmentPage> createState() => _NewAppointmentPageState();
}

class _NewAppointmentPageState extends State<NewAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _dio = dio_package.Dio();
  final _secureStorage = const FlutterSecureStorage();
  final _isarService = IsarService();

  String? _selectedLead;
  String? _selectedStatus;
  final TextEditingController _scheduledTimeController =
      TextEditingController();

  List<dynamic> _leads = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Don't pre-fill here, do it after leads are fetched
    _fetchLeads().then((_) {
      if (widget.initialAppointmentData != null) {
        // Find if the pre-filled customer_name exists in the fetched leads
        final initialCustomerName = widget.initialAppointmentData!.customerName;
        if (_leads.any((lead) => lead['name'] == initialCustomerName)) {
          _selectedLead = initialCustomerName;
        } else {
          _selectedLead = null; // Set to null if not found to avoid assertion error
        }
        _selectedStatus = widget.initialAppointmentData!.status;
        _scheduledTimeController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.initialAppointmentData!.scheduledTime);
        setState(() {}); // Trigger rebuild to update dropdowns
      }
    });
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) {
        Get.snackbar('Error', 'Session expired. Please log in again.');
        return;
      }

      final response = await _dio.get(
        'https://mysahayog.com/api/resource/Lead',
        queryParameters: {
          'fields': jsonEncode(['name', 'first_name']),
        },
        options: dio_package.Options(
          headers: {'Cookie': 'sid=$sid'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _leads = response.data['data'];
        });
      } else {
        Get.snackbar('Error', 'Failed to fetch leads');
      }
    } on dio_package.DioException catch (e) {
      Get.offAll(() => ErrorPage(errorMessage: e.response?.data['message'] ?? 'Failed to fetch leads. Contact admin.'));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final isUpdating = widget.initialAppointmentData != null;
      final appointment = isUpdating ? widget.initialAppointmentData! : Appointment();

      appointment
        ..customerName = _selectedLead!
        ..scheduledTime = DateTime.parse(_scheduledTimeController.text)
        ..status = _selectedStatus
        ..syncStatus = SyncStatus.pending
        ..lastModified = DateTime.now();

      await _isarService.saveAppointment(appointment);

      widget.onAppointmentCreated?.call();
      Get.back(result: true);
      Get.snackbar(
          'Success', isUpdating ? 'Appointment updated locally.' : 'Appointment saved locally.');

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialAppointmentData != null ? 'Edit Appointment' : 'New Appointment'),
        backgroundColor: const Color(0xFF006767),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Customer Name'),
                      // ignore: deprecated_member_use
                      value: _selectedLead,
                      items: _leads.map<DropdownMenuItem<String>>((lead) {
                        return DropdownMenuItem<String>(
                          value: lead['name'],
                          child: Text(lead['first_name'] ?? 'N/A'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLead = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a customer' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Status'),
                      // ignore: deprecated_member_use
                      value: _selectedStatus,
                      items: ['Open', 'Unverified', 'Close']
                          .map<DropdownMenuItem<String>>((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a status' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _scheduledTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Scheduled Time',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            final dateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                            _scheduledTimeController.text =
                                DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(dateTime);
                          }
                        }
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please select a time'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006767),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Appointment',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
