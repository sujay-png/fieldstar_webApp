import 'dart:math';
import 'package:field_star/model/complaint_model.dart';
import 'package:field_star/model/customer_model.dart';
import 'package:field_star/model/tech_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TechnicianRepository {
  final _supabase = Supabase.instance.client;
  //=========================Edit and Delete Customer=================================
  Future<void> updateCustomer({
    required String? id,
    required String customerName,
    required String phone,
    required String hotelName,
    required String location,
  }) async {
    if (id == null || id.isEmpty) {
      throw Exception('Customer id is null');
    }

    final response = await Supabase.instance.client
        .from('customer')
        .update({
          'cust_name': customerName,
          'cust_phno': phone,
          'cust_hotelname': hotelName,
          'cust_location': location,
        })
        .eq('id', id)
        .select();

  
    if (response.isEmpty) {
      throw Exception('No row updated. Wrong id or RLS blocking.');
    }
  }

  Future<void> deleteCustomer({required dynamic id}) async {
    await _supabase.from('customer').delete().eq('id', id);
  }

  //============================insert technician===========================
  Future<void> registerTechnician(TechModel technician) async {
    try {
     
      await _supabase.from('technician').insert(technician.toMap());
    } catch (e) {
      throw Exception('Failed to register technician: $e');
    }
  }
  //========================Fetch Technician =================================

  Future<List<TechModel>> fetchTechnicians() async {
    final response = await _supabase.from('technician').select('*');
    return (response as List<dynamic>)
        .map((tech) => TechModel.fromMap(tech))
        .toList();
  }

  //========================Asign technician==============================
  // technician_repository.dart
  Future<void> assignTechnician({
  required String ticketId,
  required int technicianId,
  required String technicianName,
}) async {
  try {
    final complaint = await _supabase
        .from('Raise_complaint')
        .select('id')
        .eq('tickectid', ticketId)
        .maybeSingle();

    final complaintId = complaint != null
        ? complaint['id'] as int
        : int.tryParse(ticketId) ?? 0;

    await _supabase.from('complaint_technicians').upsert({
      'complaint_id': complaintId,
      'technician_id': technicianId,
      'technician_name': technicianName,
    }, onConflict: 'complaint_id,technician_id');

    await _supabase
        .from('Raise_complaint')
        .update({'tech_status': 'Assigned'})
        .eq('id', complaintId);
  } catch (e) {
    rethrow;
  }
}

  //=======================Fetch complaint========================

Future<List<ComplaintModel>> fetchComplaints() async {
  final data = await _supabase
      .from('Raise_complaint')
      .select('*, complaint_technicians(technician_id, technician_name)')
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
      .toList();
}
  //=====================Count technician=======================
Future<Map<String, dynamic>> getTechnicianStats({String? technicianId}) async {
  final technicians = await _supabase.from('technician').select('id');
  final available = await _supabase.from('Raise_complaint').select('technician_id').eq('tech_status', 'Pending');
  final activeJobs = await _supabase.from('Raise_complaint').select('technician_id').eq('tech_status', 'Assigned');
  var query = _supabase.from('service_ratings').select('rating');
  
  if (technicianId != null && technicianId.isNotEmpty) {
    query = query.eq('technician_id', technicianId);
  }

  final List<dynamic> ratings = await query; 
  double avgRating = 0.0;
  if (ratings.isNotEmpty) {
    final validRatings = ratings.where((item) => item['rating'] != null);    
    if (validRatings.isNotEmpty) {
      final totalSum = validRatings.fold<num>(0, (sum, item) => sum + (item['rating'] as num));
      avgRating = totalSum / validRatings.length;
    }
  }
  return {
    'total': technicians.length,
    'available': available.length,
    'activeJobs': activeJobs.length,
    'avgRating': avgRating.toStringAsFixed(1),
  };
}
  //===================Register customer==================================

  Future<void> registerCustomerWithAuth({
    required String customerName,
    required String place,
    required String phone,
    required String location,
    required String hotelName,
    required int totalEquipment,
    required String email,
    required String password,
  }) async {
   
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': customerName, 'role': 'customer'},
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create auth user');
    }

    final userId = authResponse.user!.id;
  

    await _supabase
        .from('customer')
        .update({
          'cust_name': customerName,
          'cust_phno': phone,
          'cust_location': location,
          'cust_place': place,
          'cust_hotelname': hotelName,
          'total_equipment': totalEquipment,
        })
        .eq('id', userId); 

  }

  //========================Fetch customer================================
  Future<List<CustomerModel>> fetchcustomer() async {
  final response = await Supabase.instance.client
      .from('customer')
      .select(
        'id, cust_name, cust_phno, cust_location, cust_place, cust_hotelname, total_equipment, revenue_ytd, Raise_complaint(id, service_required)',
      );

  return response.map<CustomerModel>((e) {
    final complaints = e['Raise_complaint'] as List? ?? [];

    final equipmentCount = complaints
        .map((r) => r['service_required']?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .length;

    return CustomerModel.fromMap({
      ...e,
      'complaint_count': complaints.length,
      'equipment_count': equipmentCount,
    });
  }).toList();
}

//=======================Updated technician=======================
  Future<void> updatetechnician(TechModel technician) async {
    await _supabase
        .from('technician')
        .update(technician.toMap())
        .eq('id', technician.id!);
  }
//==================Delete technician=============================
  Future<void> deletetechnician({required dynamic id}) async {
    final int? parsedId = int.tryParse(id.toString());
    if (parsedId == null) {
      return;
    }
    await _supabase
        .from('Raise_complaint')
        .update({
          'technician_id': null,
          'tech_status': 'pending',
          'technician_name': null,
        })
        .eq('technician_id', parsedId);

  
    await _supabase.from('technician').delete().eq('id', parsedId);
  }


//==============================Get technician KPi box count==================================
 Future<Map<String, dynamic>> getActiveComplaintCount(String technicianId) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
  final endOfDay = DateTime(today.year, today.month, today.day + 1).toIso8601String();

  final results = await Future.wait([
    // Active jobs
    _supabase.from('Raise_complaint')
        .select('id')
        .eq('technician_id', technicianId) // Ensure this column name matches your DB exactly
        .eq('tech_status', 'Assigned'),

    // Jobs today - Using range to handle time-stamped dates

   _supabase .from('Raise_complaint')
    .select('id')
    .eq('technician_id', int.parse(technicianId))
    .eq('tech_status', 'Assigned')
    .gte('created_at', startOfDay)
    .lt('created_at', endOfDay),

    // Ratings
   _supabase
        .from('service_ratings')
        .select('rating')
        .eq('technician_id', 'TECH-$technicianId')
        .not('rating', 'is', null),
  
      
  ]);

    final activeJobs = (results[0] as List).length;
  final jobsToday = (results[1] as List).length;
  final ratings = results[2] as List;

  final avgRating = ratings.isEmpty
      ? 0.0
      : ratings.fold<double>(
            0,
            (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0),
          ) /
          ratings.length;

  return {
    'activeJobs': activeJobs,
    'jobsToday': jobsToday,
    'rating': avgRating, 
    'totalRatings': ratings.length,
  };
}

Future<double> getratings(String technicianId) async {
  final response = await _supabase
      .from('service_ratings')
      .select('rating')
      .eq('technician_id', technicianId)
      .not('rating', 'is', null);

  final ratings = response as List;

  if (ratings.isEmpty) return 0.0;

  final avg = ratings.fold<double>(
        0, (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0),
      ) / ratings.length;

  return double.parse(avg.toStringAsFixed(1));
}

  //=================================Get dashboard count==============================================
Future<Map<String, dynamic>> fetchDashboardStats(String technicianId) async {
  final todayStart = DateTime.now().toLocal();
  final todayOnly = DateTime(todayStart.year, todayStart.month, todayStart.day);
  final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));

  final raw = await _supabase
      .from('Raise_complaint')
      .select('id, complaint_status, created_at, technician_id');

  final all = (raw as List).cast<Map<String, dynamic>>();

  int activeToday = 0, activeYesterday = 0;
  int completedToday = 0, completedYesterday = 0;
  int totalPending = 0, totalCompleted = 0;
  final activeTechIds = <dynamic>{};
  final allTechIds = <dynamic>{};

  for (final c in all) {
    final status = c['complaint_status'];
    final techId = c['technician_id'];
    final date = DateTime.tryParse(c['created_at']?.toString() ?? '')?.toLocal();
    final isToday = date != null && !date.isBefore(todayOnly);
    final isYesterday = date != null &&
        date.isAfter(yesterdayOnly) &&
        date.isBefore(todayOnly);

    if (status == 'pending') {
      totalPending++;
      activeToday++;
      if (isYesterday) activeYesterday++;
      if (techId != null) activeTechIds.add(techId);
    }

    if (status == 'Completed') {
      totalCompleted++;
      if (isToday) completedToday++;
      if (isYesterday) completedYesterday++;
    }

    if (techId != null) allTechIds.add(techId);
  }

  final offlineTechIds = allTechIds.difference(activeTechIds);

  return {
    'activeComplaints': activeToday,
    'completedToday': completedToday,
    'pendingComplaints': totalPending,
    'completedComplaints': totalCompleted,
    'activeTechnicians': activeTechIds.length,
    'offlineTechnicians': offlineTechIds.length,
    'complaintTrend': _trend(activeToday, activeYesterday),
    'completedTrend': _trend(completedToday, completedYesterday),
  };
}

double _trend(int todayCount, int yesterdayCount) {
  if (yesterdayCount == 0) return 0;
  return ((todayCount - yesterdayCount) / yesterdayCount) * 100;
}


//=======================save technician to the auth and technician tabel============================================
  Future<void> registerTechnicianWithAuth({
    required String fullName,
    required String techId,
    required String phone,
    required String location,
    required String specialization,
    required String email,
    required String password,
  }) async {
 
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': 'technician'},
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create auth user');
    }

    final userId = authResponse.user!.id;
   
    await _supabase.from('technician').insert({
      'Full_name': fullName,
      'TechID': techId,
      'Phone_no': phone,
      'Location': location,
      'Specialization': specialization,
      'user_id': userId, 
    });

  }
  //============================Fetch customer stats=========================
Future<Map<String, dynamic>> fetchCustomerStats() async {
  final results = await Future.wait([
    _supabase.from('customer').select('total_equipment, created_at'),
    _supabase
        .from('Raise_complaint')
        .select('service_required')
        .not('service_required', 'is', null),
  ]);

  final all = results[0] as List;
  final complaints = results[1] as List;

  final totalCustomers = all.length;

  
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final thisMonthCount = all.where((c) {
    final created = DateTime.tryParse(c['created_at']?.toString() ?? '');
    return created != null && created.isAfter(thisMonthStart);
  }).length;

  final totalEquipment = all.fold<int>(
    0,
    (sum, c) => sum + ((c['total_equipment'] as num?)?.toInt() ?? 0),
  );
  final totalServiceEquipment = complaints.length;

 
 final distinctEquipmentTypes = complaints
    .map((c) {
      final raw = c['service_required']?.toString().trim() ?? '';
      return raw.contains(' - ') ? raw.split(' - ').first.trim() : raw;
    })
    .where((s) => s.isNotEmpty)
    .toSet();

  return {
    'totalCustomers': totalCustomers,
    'thisMonthCount': thisMonthCount,
    'totalEquipment': totalEquipment,
    'totalServiceEquipment': totalServiceEquipment,      
    'distinctEquipmentTypes': distinctEquipmentTypes,     
    'distinctEquipmentCount': distinctEquipmentTypes.length,
  };
}

//=================================Save Complaint from webapp====================================
Future<void> savecomplaints({
  required String categoryName,
  required String problem,
  required String priorityLevel,
  required String ticketId,
  String? serviceRequired,
  required String servicetype,
  required String otp,
  bool isJobCard = false,
bool isFieldService = false,

})async{
 

  await _supabase.from('Raise_complaint').insert({
    'Category_name': categoryName,
    'service_required': serviceRequired,
    'problem': problem,
    'priority_level': priorityLevel,
    'tickectid': ticketId,
    'otp': otp,
    'complaint_status': 'pending',
    'tech_status': 'Pending',
    'Service_type':servicetype,
      'is_job_card': isJobCard,
    'is_field_service': isFieldService,

  });
}
}

