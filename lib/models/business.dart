class Business {
  final String id;
  final String businessName;
  final String? businessCode;
  final String? logoUrl;
  final String apiKey;
  final String apiUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.businessName,
    this.businessCode,
    this.logoUrl,
    required this.apiKey,
    required this.apiUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      businessCode: json['business_code'] as String?,
      logoUrl: json['logo_url'] as String?,
      apiKey: json['api_key'] as String,
      apiUrl: json['api_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'business_code': businessCode,
      'logo_url': logoUrl,
      'api_key': apiKey,
      'api_url': apiUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

