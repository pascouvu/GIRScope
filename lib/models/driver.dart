import 'package:girscope/utils/json_utils.dart';

class Driver {
  final String id;
  final String name;
  final String firstName;
  final String badge;
  final String? pubsnBadge;
  final String? ctrlBadge;
  final String code;
  final String? pinCode;
  final String? departmentId;
  final String departmentName;
  final bool? activityPrompt;
  final bool? ncePrompt;
  final String? notes;

  Driver({
    required this.id,
    required this.name,
    required this.firstName,
    required this.badge,
    this.pubsnBadge,
    this.ctrlBadge,
    required this.code,
    this.pinCode,
    this.departmentId,
    required this.departmentName,
    this.activityPrompt,
    this.ncePrompt,
    this.notes,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
      firstName: safeStringValue(json['first_name'] ?? json['firstname']),
      badge: safeStringValue(json['badge']),
      pubsnBadge: safeStringValue(json['pubsn_badge']),
      ctrlBadge: safeStringValue(json['ctrl_badge']),
      code: safeStringValue(json['code']),
      pinCode: safeStringValue(json['pin_code']),
      departmentId: safeStringValue(json['department']?['id']),
      departmentName: safeStringValue(json['department']?['name'] ?? json['department']),
      activityPrompt: json['activity_prompt'] as bool?,
      ncePrompt: json['nce_prompt'] as bool?,
      notes: safeStringValue(json['notes']),
    );
  }

  

  String get fullName => '$firstName $name'.trim();
}