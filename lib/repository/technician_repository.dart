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
Future<List<ComplaintModel>> fetchComplaints({
  int page = 0,
  int pageSize = 10,
  String? searchQuery,
  List<String>? statusFilters, 
}) async {
  try {
    var query = _supabase
        .from('Raise_complaint')
        .select('*, complaint_technicians(technician_id, technician_name)');

    final q = searchQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      query = query.or(
        'tickectid.ilike.%$q%,'
        'Category_name.ilike.%$q%,'
        'service_required.ilike.%$q%,'
        'problem.ilike.%$q%',
      );
    }

    if (statusFilters != null && statusFilters.isNotEmpty) {
      final clause = statusFilters.map((s) => 'complaint_status.ilike.$s').join(',');
      query = query.or(clause);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize - 1);

    return (data as List)
        .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Exception('Failed to load complaints: $e');
  }
}
  //=====================Count technician=======================
Future<Map<String, dynamic>> getTechnicianStats({String? technicianId}) async {
  try {
    final result = await _supabase.rpc('get_technician_stats');
    return Map<String, dynamic>.from(result as Map);
  } catch (e) {
    throw Exception('Failed to load technician stats: $e');
  }
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
Future<List<CustomerModel>> fetchcustomer({
  int page = 0,
  int pageSize = 10,
  String? searchQuery,
}) async {
  try {
    var query = Supabase.instance.client
        .from('customer')
        .select(
          'id, cust_name, cust_phno, cust_location, cust_place, cust_hotelname, total_equipment, revenue_ytd, Raise_complaint(id, service_required)',
        );

    final q = searchQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      query = query.or(
        'cust_name.ilike.%$q%,'
        'cust_phno.ilike.%$q%,'
        'cust_location.ilike.%$q%,'
        'cust_place.ilike.%$q%,'
        'cust_hotelname.ilike.%$q%',
      );
    }

    final response = await query.range(page * pageSize, page * pageSize + pageSize - 1);

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
  } catch (e) {
    throw Exception('Failed to load customers: $e');
  }
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
  final techId = int.tryParse(technicianId);

  if (techId == null) {
    return {
      'activeJobs': 0,
      'jobsToday': 0,
    };
  }

  final today = DateTime.now();

  final startOfDay = DateTime(
    today.year,
    today.month,
    today.day,
  ).toIso8601String();

  final endOfDay = DateTime(
    today.year,
    today.month,
    today.day + 1,
  ).toIso8601String();

  final activeJobsRes = await _supabase
      .from('Raise_complaint')
      .select('id')
      .eq('technician_id', techId)
      .eq('tech_status', 'Assigned');

  final jobsTodayRes = await _supabase
      .from('Raise_complaint')
      .select('id')
      .eq('technician_id', techId)
      .eq('tech_status', 'Assigned')
      .gte('created_at', startOfDay)
      .lt('created_at', endOfDay);

  return {
    'activeJobs': activeJobsRes.length,
    'jobsToday': jobsTodayRes.length,
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
  try {
    final result = await _supabase.rpc('get_dashboard_stats');
    return Map<String, dynamic>.from(result as Map);
  } catch (e) {
    throw Exception('Failed to load dashboard stats: $e');
  }
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
  try {
    final result = await _supabase.rpc('get_customer_stats');
    return Map<String, dynamic>.from(result as Map);
  } catch (e) {
    throw Exception('Failed to load customer stats: $e');
  }
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

