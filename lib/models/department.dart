class Department {
  final String id;
  final String name;

  Department({
    required this.id,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}