// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class NewAppointmentPage extends StatefulWidget {
  final VoidCallback? onAppointmentCreated;
  final Map<String, dynamic>? initialAppointmentData;

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

  String? _selectedLead;
  String? _selectedStatus;
  final TextEditingController _scheduledTimeController =
      TextEditingController();

  List<dynamic> _leads = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLeads(); // Still need to fetch leads for the dropdown

    if (widget.initialAppointmentData != null) {
      _selectedLead = widget.initialAppointmentData!['customer_name']; // Pre-fill customer name
      _selectedStatus = widget.initialAppointmentData!['status']; // Pre-fill status
      _scheduledTimeController.text = widget.initialAppointmentData!['scheduled_time'] ?? ''; // Pre-fill scheduled time
    }
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
      Get.snackbar('Error', e.response?.data['message'] ?? 'An error occurred');
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

      try {
        final sid = await _secureStorage.read(key: 'sid');
        if (sid == null) {
          Get.snackbar('Error', 'Session expired. Please log in again.');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final isUpdating = widget.initialAppointmentData != null;
        final String apiUrl;
        final String successMessage;
        final String errorMessage;
        final String requestMethod;

        if (isUpdating) {
          final appointmentName = widget.initialAppointmentData!['name'];
          apiUrl = 'https://mysahayog.com/api/resource/Appointment/$appointmentName';
          successMessage = 'Appointment updated successfully';
          errorMessage = 'Failed to update appointment';
          requestMethod = 'PUT'; // Frappe uses PUT for updates
        } else {
          apiUrl = 'https://mysahayog.com/api/resource/Appointment';
          successMessage = 'Appointment created successfully';
          errorMessage = 'Failed to create appointment';
          requestMethod = 'POST';
        }

        final appointmentData = {
          'customer_name': _selectedLead,
          'status': _selectedStatus,
          'scheduled_time': _scheduledTimeController.text,
          'appointment_with': 'Lead',
          'party': _selectedLead,
        };

        dio_package.Response response;
        if (requestMethod == 'PUT') {
          response = await _dio.put(
            apiUrl,
            data: appointmentData,
            options: dio_package.Options(
              headers: {'Cookie': 'sid=$sid'},
              contentType: 'application/json',
            ),
          );
        } else {
          response = await _dio.post(
            apiUrl,
            data: appointmentData,
            options: dio_package.Options(
              headers: {'Cookie': 'sid=$sid'},
              contentType: 'application/json',
            ),
          );
        }

        if (response.statusCode == 200) {
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // ignore: use_build_context_synchronously
            Get.snackbar('Success', successMessage);
            // ignore: use_build_context_synchronously
            Get.back();
            widget.onAppointmentCreated?.call();
          });
        } else {
          Get.snackbar('Error', '$errorMessage: ${response.statusMessage}');
        }
      } on dio_package.DioException catch (e) {
        Get.snackbar(
            'Error', e.response?.data['message'] ?? 'An error occurred');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
