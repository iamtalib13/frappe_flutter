import 'package:isar/isar.dart';
import 'package:frappe_flutter/models/sync_status.dart';

part 'appointment_model.g.dart'; // Isar will generate this file

@collection
class Appointment {
  Id id = Isar.autoIncrement; // Isar's auto-incrementing primary key

  String? name; // Frappe's actual Appointment ID (e.g., APPT0001)
  late String customerName;
  late DateTime scheduledTime;
  String? status; // e.g., 'Open', 'Closed', 'Cancelled'

  @Enumerated(EnumType.name)
  late SyncStatus syncStatus;
  DateTime? lastModified; // Timestamp for last modification (useful for sync conflicts)
}