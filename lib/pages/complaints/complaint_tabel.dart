import 'package:field_star/model/complaint_model.dart';
import 'package:field_star/pages/complaints/assign_tech.dart';
import 'package:field_star/repository/technician_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum Priority { high, medium, low }

enum ComplaintStatus { pending, assigned, inProgress, completed }

Priority _mapPriority(String? val) {
  switch (val?.toLowerCase()) {
    case 'high':
      return Priority.high;
    case 'medium':
      return Priority.medium;
    default:
      return Priority.low;
  }
}

ComplaintStatus _mapStatus(String? val) {
  switch (val?.toLowerCase()) {
    case 'assigned':
      return ComplaintStatus.assigned;
    case 'in progress':
      return ComplaintStatus.inProgress;
    case 'completed':
      return ComplaintStatus.completed;
    default:
      return ComplaintStatus.pending;
  }
}

class ComplaintsTable extends StatefulWidget {
  final String searchQuery;
  const ComplaintsTable({super.key, this.searchQuery = ''});

  @override
  State<ComplaintsTable> createState() => _ComplaintsTableState();
}

class _ComplaintsTableState extends State<ComplaintsTable> {

  final _repo = TechnicianRepository();
  late Future<List<ComplaintModel>> _complaintsFuture;
  final ScrollController _horizontalscroll = ScrollController();
  String? expandedTicketId;

  @override
  void dispose() {
    _horizontalscroll.dispose();
    super.dispose();
  }

  final int _pageSize = 10;
  int _currentPage = 0;

  @override
  void initState() {
    _loadPage();
    super.initState();
   
  }
@override
void didUpdateWidget(covariant ComplaintsTable oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.searchQuery != widget.searchQuery) {
    setState(() {
      _currentPage = 0; 
      _loadPage();
    });
  }
}
  void _refresh() => setState(() {
    _complaintsFuture = _repo.fetchComplaints(
      page: _currentPage,
      pageSize: _pageSize,
       searchQuery: widget.searchQuery,
    );
  });

 void _loadPage() {
  _complaintsFuture = _repo.fetchComplaints(
    page: _currentPage,
    pageSize: _pageSize,
    searchQuery: widget.searchQuery,
  );
}

  void _nextPage() {
    setState(() {
      _currentPage++;
      _loadPage();
    });
  }

  void _previousPage() {
    if (_currentPage == 0) return;

    setState(() {
      _currentPage--;
      _loadPage();
    });
  }
  // ── PRIORITY BADGE ───────────────────────────────────────────────────────────
  Widget _priorityBadge(Priority priority) {
    late String label;
    late Color bg;
    late Color textColor;
    switch (priority) {
      case Priority.high:
        label = 'High Priority';
        bg = const Color(0xFFFFE4E4);
        textColor = const Color(0xFFE05252);
        break;
      case Priority.medium:
        label = 'Medium';
        bg = const Color(0xFFFFF3CD);
        textColor = const Color(0xFFB8860B);
        break;
      case Priority.low:
        label = 'Low';
        bg = const Color(0xFFE8E8FF);
        textColor = const Color(0xFF6666CC);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ============== STATUS BADGE ====================================
  Widget _statusBadge(ComplaintStatus status) {
    late String label;
    late Color bg;
    late Color textColor;
    switch (status) {
      case ComplaintStatus.pending:
        label = 'Pending';
        bg = const Color(0xFFFFF3CD);
        textColor = const Color(0xFFB8860B);
        break;
      case ComplaintStatus.assigned:
        label = 'Assigned';
        bg = const Color(0xFFE8E8FF);
        textColor = const Color(0xFF6666CC);
        break;
      case ComplaintStatus.inProgress:
        label = 'In Progress';
        bg = const Color(0xFFE0F0FF);
        textColor = const Color(0xFF3399CC);
        break;
      case ComplaintStatus.completed:
        label = 'Completed';
        bg = const Color(0xFFD4F5E2);
        textColor = const Color(0xFF2E9E5B);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ── TECHNICIAN CELL ──────────────────────────────────────────────────────────
  Widget _technicianCell(ComplaintModel c, ComplaintStatus status) {
    if (status == ComplaintStatus.pending || c.technicians.isEmpty) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AssignTechnicianDialog(
              ticketId: c.ticketId,
              onAssign: (techList) async {
                for (final tech in techList) {
                  try {
                    final parsedId = int.tryParse(tech.id);
                    if (parsedId == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invalid technician ID for ${tech.name}',
                          ),
                        ),
                      );
                      continue;
                    }
                    await _repo.assignTechnician(
                      ticketId: c.ticketId.isNotEmpty ? c.ticketId : c.id,
                      technicianId: parsedId,
                      technicianName: tech.name,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${tech.name} assigned successfully'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to assign ${tech.name}: $e'),
                      ),
                    );
                  }
                }
                if (!mounted) return;
                _refresh();
              },
            ),
          );
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_alt_1_outlined,
              size: 16,
              color: Color(0xFFE8680A),
            ),
            SizedBox(width: 6),
            Text(
              'Assign',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE8680A),
              ),
            ),
          ],
        ),
      );
    }

    final first = c.technicians.first;
    final initials = first.name.length >= 2
        ? first.name.substring(0, 2).toUpperCase()
        : '?';
    final extra = c.technicians.length - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF3B82F6),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            extra > 0 ? '${first.name} +$extra' : first.name,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── TICKET CELL (ID + timestamp) ─────────────────────────────────────────────
  Widget _ticketCell(ComplaintModel c) {
    String formattedDate = c.createdAt;
    try {
      final dt = DateTime.parse(c.createdAt).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      formattedDate =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  $hour:$minute $amPm';
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          c.ticketId.isNotEmpty ? c.ticketId : '#${c.id}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 11,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                formattedDate,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── CATEGORY CELL ────────────────────────────────────────────────────────────
  Widget _categoryCell(ComplaintModel c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          c.categoryName ?? '—',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          c.serviceRequired ?? '—',
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── PROBLEM CELL ─────────────────────────────────────────────────────────────
  Widget _problemCell(ComplaintModel c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          c.problem ?? '—',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          softWrap: true,
        ),

        if (c.date != null) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 11,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 3),
              Text(
                c.date!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //=============================Fetch complaints===========================================
    return FutureBuilder<List<ComplaintModel>>(
      future: _complaintsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFE05252),
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load complaints\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

     final rows = snapshot.data ?? [];

        return Scrollbar(
          controller: _horizontalscroll,
          thumbVisibility: true,
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              controller: _horizontalscroll,
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rows.isEmpty)
                      const SizedBox(
                        width: 400,
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No complaints found.',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: const Color(0xFFEEEEEE)),
                        // =========================Datatabel=======================================================
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width,
                          ),
                          child: DataTable(
                            columnSpacing: 16,
                            horizontalMargin: 20,
                            headingRowHeight: 42,
                            dataRowMinHeight: 60,
                            dataRowMaxHeight: 64,
                            dividerThickness: 1,
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFFAFAFA),
                            ),
                            headingTextStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                            // ── Columns ──────────────────────────────────────────
                            columns: const [
                              DataColumn(label: Text('TICKET')),
                              DataColumn(label: Text('CATEGORY')),
                              DataColumn(label: Text('PROBLEM')),
                              DataColumn(label: Text('PRIORITY')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('TECHNICIAN')),
                            ],
                            // ── Rows ─────────────────────────────────────────────
                            rows: rows.map((c) {
                              final priority = _mapPriority(c.priorityLevel);
                              final status = _mapStatus(c.techstatus);
                              return DataRow(
                                cells: [
                                  DataCell(_ticketCell(c)),
                                  DataCell(_categoryCell(c)),
                                  DataCell(_problemCell(c)),
                                  DataCell(_priorityBadge(priority)),
                                  DataCell(_statusBadge(status)),
                                  DataCell(_technicianCell(c, status)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Page ${_currentPage + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 12),

                          OutlinedButton(
                            onPressed: _currentPage == 0 ? null : _previousPage,
                            child: const Text('Previous'),
                          ),

                          const SizedBox(width: 8),

                          OutlinedButton(
                            onPressed: rows.length < _pageSize
                                ? null
                                : _nextPage,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
