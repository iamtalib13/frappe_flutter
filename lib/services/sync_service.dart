import 'package:dio/dio.dart' as dio_package;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frappe_flutter/models/lead_model.dart';
import 'package:frappe_flutter/models/sync_status.dart';
import 'package:frappe_flutter/services/isar_service.dart';
import 'package:get/get.dart';

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

        final response = await _dio.post(
          'https://mysahayog.com/api/resource/Lead',
          data: leadData,
          options: dio_package.Options(
            headers: {'Cookie': 'sid=$sid'},
            contentType: 'application/json',
          ),
        );

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
}
