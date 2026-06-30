class AssignedTechnician {
  final int id;
  final String name;
  AssignedTechnician({required this.id, required this.name});

  factory AssignedTechnician.fromJson(Map<String, dynamic> json) {
    return AssignedTechnician(
      id: json['technician_id'] as int,
      name: json['technician_name'] ?? '',
    );
  }
}

class ComplaintModel {
  final String id;
  final String ticketId;
  final String createdAt;
  final String? categoryName;
  final String? serviceRequired;
  final String? problem;
  final String? priorityLevel;
  final String? date;
  final String? imageUrl;
  final String? audioUrl;
  final String? otp;
  final List<AssignedTechnician> technicians; // ← replaces single id/name
  final String techstatus;
  final String? complaintstatus;

  ComplaintModel({
    required this.id,
    required this.ticketId,
    required this.createdAt,
    this.categoryName,
    this.serviceRequired,
    this.problem,
    this.priorityLevel,
    this.date,
    this.imageUrl,
    this.audioUrl,
    this.otp,
    this.technicians = const [],
    required this.techstatus,
    this.complaintstatus,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    final techList = (json['complaint_technicians'] as List? ?? [])
        .map((t) => AssignedTechnician.fromJson(t as Map<String, dynamic>))
        .toList();

    return ComplaintModel(
      id: json['id'].toString(),
      ticketId: json['tickectid'] ?? '',
      createdAt: json['created_at'] ?? '',
      categoryName: json['Category_name'],
      serviceRequired: json['service_required'],
      problem: json['problem'],
      priorityLevel: json['priority_level'],
      date: json['Date'],
      imageUrl: json['image_url'],
      audioUrl: json['audio_url'],
      otp: json['otp'],
      technicians: techList,
      techstatus: json['tech_status'] ?? 'Pending',
      complaintstatus: json['complaint_status'] ?? 'pending',
    );
  }
}