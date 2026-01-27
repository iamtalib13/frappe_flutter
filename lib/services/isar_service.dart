import 'package:frappe_flutter/models/lead_model.dart';
import 'package:frappe_flutter/models/appointment_model.dart';
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

  // Save a single appointment
  Future<void> saveAppointment(Appointment appointment) async {
    await isar.writeTxn(() async {
      await isar.appointments.put(appointment);
    });
  }

  // Save multiple appointments
  Future<void> saveAppointments(List<Appointment> appointments) async {
    await isar.writeTxn(() async {
      await isar.appointments.putAll(appointments);
    });
  }

  // Get all appointments
  Future<List<Appointment>> getAllAppointments() async {
    return await isar.appointments.where().findAll();
  }

  // Get appointments by sync status
  Future<List<Appointment>> getAppointmentsBySyncStatus(SyncStatus status) async {
    return await isar.appointments.filter().syncStatusEqualTo(status).findAll();
  }

  // Find an appointment by its Frappe 'name' (server ID)
  Future<Appointment?> getAppointmentByName(String name) async {
    return await isar.appointments.filter().nameEqualTo(name).findFirst();
  }

  // Find an appointment by Isar ID
  Future<Appointment?> getAppointmentById(Id id) async {
    return await isar.appointments.get(id);
  }

  // Delete an appointment
  Future<void> deleteAppointment(Id id) async {
    await isar.writeTxn(() async {
      await isar.appointments.delete(id);
    });
  }

  // Stream all appointments (useful for reactive UI updates)
  Stream<List<Appointment>> listenToAppointments() {
    return isar.appointments.where().watch(fireImmediately: true);
  }
}