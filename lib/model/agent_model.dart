// Defines the data model for an AI Agent.

class Agent {
  final String id;
  final String name;
  final String type; // e.g., "DealHunter", "TaskManager", "Concierge"
  final String? linkedPropertyId; // Optional: Agent can be linked to a specific property
  final String createdBy; // User ID of the creator
  final String status; // e.g., "Active", "Idle", "Processing", "Disabled"

  Agent({
    required this.id,
    required this.name,
    required this.type,
    this.linkedPropertyId,
    required this.createdBy,
    required this.status,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      linkedPropertyId: json['linkedPropertyId'] as String?,
      createdBy: json['createdBy'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'linkedPropertyId': linkedPropertyId,
      'createdBy': createdBy,
      'status': status,
    };
  }
}
