// Defines the data model for a Property.

class Property {
  final String id;
  final String address; // For now, a simple string. Could be a structured Address object later.
  final String ownerId; // User ID of the owner
  final List<String> agentIds; // List of Agent IDs associated with this property
  final List<String> moduleIds; // List of active module identifiers (e.g., "Tasks", "Payments", "Documents")

  Property({
    required this.id,
    required this.address,
    required this.ownerId,
    List<String>? agentIds,
    List<String>? moduleIds,
  }) : agentIds = agentIds ?? [],
       moduleIds = moduleIds ?? [];

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      address: json['address'] as String,
      ownerId: json['ownerId'] as String,
      agentIds: json['agentIds'] != null ? List<String>.from(json['agentIds']) : [],
      moduleIds: json['moduleIds'] != null ? List<String>.from(json['moduleIds']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'ownerId': ownerId,
      'agentIds': agentIds,
      'moduleIds': moduleIds,
    };
  }
}
