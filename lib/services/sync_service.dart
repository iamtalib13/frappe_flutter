import 'package:dio/dio.dart' as dio_package;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frappe_flutter/models/lead_model.dart';
import 'package:frappe_flutter/models/appointment_model.dart';
import 'package:frappe_flutter/models/sync_status.dart';
import 'package:frappe_flutter/services/isar_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SyncService {
  final _isarService = IsarService();
  final _dio = dio_package.Dio();
  final _secureStorage = const FlutterSecureStorage();

  Future<void> syncPendingLeads() async {
    final pendingLeads = await _isarService.getLeadsBySyncStatus(SyncStatus.pending);

    for (var lead in pendingLeads) {
      try {
        final sid = await _secureStorage.read(key: 'sid');
        if (sid == null) {
          // Handle session expiry
          return;
        }

        final leadData = {
          'doctype': 'Lead',
          'first_name': lead.firstName,
          'mobile_no': lead.mobileNo,
          'status': lead.status,
          'source': lead.source,
          'custom_product_table': [
            {
              'product': lead.product,
              'product_name': lead.productName,
              'product_amount': lead.productAmount,
            }
          ]
        };

        final isUpdating = lead.name != null;
        final String apiUrl;
        final String requestMethod;

        if (isUpdating) {
          apiUrl = 'https://mysahayog.com/api/resource/Lead/${lead.name}';
          requestMethod = 'PUT';
        } else {
          apiUrl = 'https://mysahayog.com/api/resource/Lead';
          requestMethod = 'POST';
        }

        dio_package.Response response;
        if (requestMethod == 'PUT') {
          response = await _dio.put(
            apiUrl,
            data: leadData,
            options: dio_package.Options(
              headers: {'Cookie': 'sid=$sid'},
              contentType: 'application/json',
            ),
          );
        } else {
          response = await _dio.post(
            apiUrl,
            data: leadData,
            options: dio_package.Options(
              headers: {'Cookie': 'sid=$sid'},
              contentType: 'application/json',
            ),
          );
        }

        if (response.statusCode == 200) {
          lead.syncStatus = SyncStatus.synced;
          lead.name = response.data['data']['name'];
          await _isarService.saveLead(lead);
        } else {
          lead.syncStatus = SyncStatus.failed;
          await _isarService.saveLead(lead);
        }
      } catch (e) {
        lead.syncStatus = SyncStatus.failed;
        await _isarService.saveLead(lead);
        // Optionally, log the error
      }
    }
  }

  Future<void> syncPendingAppointments() async {
    final pendingAppointments =
        await _isarService.getAppointmentsBySyncStatus(SyncStatus.pending);

    for (var appointment in pendingAppointments) {
      try {
        final sid = await _secureStorage.read(key: 'sid');
        if (sid == null) {
          // Handle session expiry
          return;
        }

        final appointmentData = {
          'doctype': 'Appointment',
          'customer_name': appointment.customerName,
          'scheduled_time':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(appointment.scheduledTime),
          'status': appointment.status,
          'appointment_with': 'Lead', // Assuming always with a Lead
          'party': appointment.customerName, // Assuming party is customerName
        };

        final isUpdating = appointment.name != null;
        final String apiUrl;
        final String requestMethod;

        if (isUpdating) {
          apiUrl = 'https://mysahayog.com/api/resource/Appointment/${appointment.name}';
          requestMethod = 'PUT';
        } else {
          apiUrl = 'https://mysahayog.com/api/resource/Appointment';
          requestMethod = 'POST';
        }

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
          appointment.syncStatus = SyncStatus.synced;
          appointment.name = response.data['data']['name'];
          await _isarService.saveAppointment(appointment);
        } else {
          appointment.syncStatus = SyncStatus.failed;
          await _isarService.saveAppointment(appointment);
        }
      } catch (e) {
        appointment.syncStatus = SyncStatus.failed;
        await _isarService.saveAppointment(appointment);
        // Optionally, log the error
      }
    }
  }
}
