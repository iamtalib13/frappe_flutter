import 'package:frappe_flutter/models/sync_status.dart';
import 'package:isar/isar.dart';

part 'lead_model.g.dart'; // Isar will generate this file

@collection
class Lead {
  Id id = Isar.autoIncrement; // Isar's auto-incrementing primary key

  String? name; // Frappe's actual Lead ID (e.g., LEAD0001)
  late String firstName;
  String? mobileNo;
  String? status;
  String? source;
  String? product; // Product name or ID
  String? productName; // Display name of the product
  double? productAmount; // Amount for the product

  @Enumerated(EnumType.name)
  late SyncStatus syncStatus;
  DateTime? lastModified; // Timestamp for last modification (useful for sync conflicts)
}