import 'package:frappe_flutter/models/lead_model.dart';
import 'package:frappe_flutter/models/sync_status.dart';
import 'package:isar/isar.dart';

import '../main.dart'; // To access the global isar instance

class IsarService {
  // Save a single lead
  Future<void> saveLead(Lead lead) async {
    await isar.writeTxn(() async {
      await isar.leads.put(lead);
    });
  }

  // Save multiple leads
  Future<void> saveLeads(List<Lead> leads) async {
    await isar.writeTxn(() async {
      await isar.leads.putAll(leads);
    });
  }

  // Get all leads
  Future<List<Lead>> getAllLeads() async {
    return await isar.leads.where().findAll();
  }

  // Get leads by sync status
  Future<List<Lead>> getLeadsBySyncStatus(SyncStatus status) async {
    return await isar.leads.filter().syncStatusEqualTo(status).findAll();
  }

  // Find a lead by its Frappe 'name' (server ID)
  Future<Lead?> getLeadByName(String name) async {
    return await isar.leads.filter().nameEqualTo(name).findFirst();
  }

  // Find a lead by Isar ID
  Future<Lead?> getLeadById(Id id) async {
    return await isar.leads.get(id);
  }

  // Delete a lead
  Future<void> deleteLead(Id id) async {
    await isar.writeTxn(() async {
      await isar.leads.delete(id);
    });
  }

  // Stream all leads (useful for reactive UI updates)
  Stream<List<Lead>> listenToLeads() {
    return isar.leads.where().watch(fireImmediately: true);
  }
}