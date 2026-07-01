import 'dart:math';
import 'package:field_star/navigation/primaryscaffold.dart';
import 'package:field_star/pages/complaints/complaint_tabel.dart';
import 'package:field_star/repository/technician_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Complaints extends StatefulWidget {
  const Complaints({super.key});

  @override
  State<Complaints> createState() => _ComplaintsState();
}

class _ComplaintsState extends State<Complaints> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController categoryname = TextEditingController();
  final TextEditingController problemdescription = TextEditingController();
  final TextEditingController servicerequired = TextEditingController();
  late Future<List<dynamic>> _complaintFuture;
  final TextEditingController priority = TextEditingController();
  final TextEditingController ticketIdCtrl = TextEditingController();
  final TextEditingController otp = TextEditingController();

  String servicetype = '';
  String prioritystatus = 'Medium';
  bool isCheckedjobcard = false;
  bool isCheckedfieldservice = false;
  final _repository = TechnicianRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    ticketIdCtrl.dispose();
    categoryname.dispose();
    problemdescription.dispose();
    servicerequired.dispose();
    priority.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    ticketIdCtrl.text = generateTicketId();
    otp.text = generateOtp();
    _complaintFuture = _repository.fetchComplaints();
  }

  void _refresh() => setState(() {
    _complaintFuture = _repository.fetchComplaints();
  });
  
  @override
  Widget build(BuildContext context) {
    return sidebar(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Complaint Management",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: const Color.fromARGB(255, 4, 6, 10),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      "Monitor and manage all service requests",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _showRegisterTechnicianDialog(context);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Add Complaints"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E9F0), width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase().trim();
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Search by TicketId, Customer, Equipments...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8), // Muted text token colors
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: ComplaintsTable(searchQuery: _searchQuery),
              ),
            ),
          ],
        ),
      ),
    );
  }
//==============================Add technician dialog=========================================
  void _showRegisterTechnicianDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add Technician",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    SizedBox(height: 15),
                    Row(
                      spacing: 15,
                      children: [
                        Text(
                          'Priority Level',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        ...['Low', 'Medium', 'High'].map<Widget>((String p) {
                          final selected = prioritystatus == p;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setDialogState(() => prioritystatus = p),
                              child: Container(
                                height: 32,
                                margin: const EdgeInsets.only(right: 6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xfffff3cd)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected
                                        ? Colors.deepOrange
                                        : Colors.blueGrey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    SizedBox(height: 15),
                    _buildField("CategoryName", '', categoryname),
                    const SizedBox(height: 15),
                    _buildField("Service Required", "", servicerequired),
                    const SizedBox(height: 15),
                    _buildField("Problem", "", problemdescription),
                    const SizedBox(height: 15),
                    CheckboxExample(
                      isCheckedjobcard: isCheckedjobcard,
                      isCheckedfieldservice: isCheckedfieldservice,
                      onJobCardChanged: (value) =>
                          setDialogState(() => isCheckedjobcard = value),
                      onFieldServiceChanged: (value) =>
                          setDialogState(() => isCheckedfieldservice = value),
                    ),

                    // ── Auth fields ──────────────────────────────────────
                    const SizedBox(height: 25),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        //=========================Add technician================================
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() => _isLoading = true);
                                try {
                                  final selectedServiceTypes = <String>[
                                    if (isCheckedjobcard) 'Job Card',
                                    if (isCheckedfieldservice) 'Field Service',
                                  ];
                                  final resolvedServiceType =
                                      selectedServiceTypes.join(', ');

                                  await _repository.savecomplaints(
                                    categoryName: categoryname.text.trim(),
                                    priorityLevel: prioritystatus,
                                    serviceRequired: servicerequired.text
                                        .trim(),
                                    problem: problemdescription.text.trim(),
                                    ticketId: ticketIdCtrl.text.trim(),
                                    otp: otp.text.trim(),
                                    servicetype: resolvedServiceType,
                                    isJobCard: isCheckedjobcard,
                                    isFieldService: isCheckedfieldservice,
                                  );
                                  final savedTicketId = ticketIdCtrl.text
                                      .trim();
                                  final savedOtp = otp.text.trim();

                                  categoryname.clear();
                                  ticketIdCtrl.clear();
                                  problemdescription.clear();
                                  servicerequired.clear();
                                  isCheckedjobcard = false;
                                  isCheckedfieldservice = false;
                                  context.push(
                                    '/otpscreen',
                                    extra: {
                                      'tickectid': savedTicketId,
                                      'otp': savedOtp,
                                    },
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Complaint registered successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _refresh();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted)
                                    setState(() => _isLoading = false);
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Save Complaint",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //==============================Helper function=====================================
  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  //=================================Generate Tickect ID===========================================
  String generateTicketId() {
    final random = Random();
    return 'FS${100000 + random.nextInt(900000)}';
  }

  //============================generate otp=================================================
  String generateOtp() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }
}
//==============================Checkbox=====================================================

class CheckboxExample extends StatelessWidget {
  final bool isCheckedjobcard;
  final bool isCheckedfieldservice;
  final ValueChanged<bool> onJobCardChanged;
  final ValueChanged<bool> onFieldServiceChanged;
  const CheckboxExample({
    super.key,
    required this.isCheckedjobcard,
    required this.isCheckedfieldservice,
    required this.onJobCardChanged,
    required this.onFieldServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color getColor(Set<WidgetState> states) {
      const Set<WidgetState> interactiveStates = <WidgetState>{
        WidgetState.pressed,
        WidgetState.hovered,
        WidgetState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue;
      }
      return Colors.red;
    }

    return Row(
      children: [
        Checkbox(
          checkColor: Colors.white,
          fillColor: WidgetStateProperty.resolveWith(getColor),
          value: isCheckedjobcard,
          onChanged: (bool? value) => onJobCardChanged(value!),
        ),
        GestureDetector(
          onTap: () => onJobCardChanged(!isCheckedjobcard),
          child: const Text('Job Card'),
        ),
        Checkbox(
          checkColor: Colors.white,
          fillColor: WidgetStateProperty.resolveWith(getColor),
          value: isCheckedfieldservice,
          onChanged: (bool? value) => onFieldServiceChanged(value!),
        ),
        GestureDetector(
          onTap: () => onFieldServiceChanged(!isCheckedfieldservice),
          child: const Text('Field Service '),
        ),
      ],
    );
  }
}
