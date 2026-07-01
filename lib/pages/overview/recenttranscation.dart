import 'package:field_star/model/complaint_model.dart';
import 'package:field_star/repository/technician_repository.dart';
import 'package:flutter/material.dart';

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

class RecentComplaintsTable extends StatefulWidget {
  final String searchQuery;
  final VoidCallback? onViewAll;

  const RecentComplaintsTable({
    super.key,
    this.onViewAll,
    required this.searchQuery,
  });

  @override
  State<RecentComplaintsTable> createState() => _RecentComplaintsTableState();
}

class _RecentComplaintsTableState extends State<RecentComplaintsTable> {
  final int _pageSize = 10;
  int _currentPage = 0;
  final _repo = TechnicianRepository();
  late Future<List<ComplaintModel>> _complaintsFuture;

  // ── Active status filters (empty = show all) ──────────────────
  final Set<ComplaintStatus> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  void _loadPage() {
    final statusValues = _activeFilters
        .map((s) {
          switch (s) {
            case ComplaintStatus.pending:
              return 'pending';
            case ComplaintStatus.completed:
              return 'Completed';
            default:
              return '';
          }
        })
        .where((s) => s.isNotEmpty)
        .toList();

    _complaintsFuture = _repo.fetchComplaints(
      page: _currentPage,
      pageSize: _pageSize,
      searchQuery: widget.searchQuery,
      statusFilters: statusValues,
    );
  }

  @override
  void didUpdateWidget(covariant RecentComplaintsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      setState(() {
        _currentPage = 0;
        _loadPage();
      });
    }
  }

  void _refresh() => setState(_loadPage);
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

  // ── Filter chip config ────────────────────────────────────────
  static const _filterOptions = [
    (
      label: 'Pending',
      status: ComplaintStatus.pending,
      color: Color(0xFFB8860B),
      bg: Color(0xFFFFF3CD),
    ),
    (
      label: 'Completed',
      status: ComplaintStatus.completed,
      color: Color(0xFF2E9E5B),
      bg: Color(0xFFD4F5E2),
    ),
  ];
//=========================================Filter chips for complete status=========================================
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: _filterOptions.map((opt) {
          final isActive = _activeFilters.contains(opt.status);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                isActive
                    ? _activeFilters.remove(opt.status)
                    : _activeFilters.add(opt.status);
                _currentPage = 0;
                _loadPage();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? opt.bg : Colors.orange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? opt.color : const Color(0xFFE2E8F0),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) ...[
                      Icon(Icons.check, size: 13, color: opt.color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? opt.color : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
//==============================Fetching complaints data from the repository and displaying it in a DataTable with pagination and filtering==============================
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

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Complaints',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    if (_activeFilters.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() {
                          _activeFilters.clear();
                          _currentPage = 0;
                          _loadPage();
                        }),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Clear filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Filter chips ──────────────────────────────────
              _buildFilterChips(),
              const SizedBox(height: 15),

              // ── DataTable ─────────────────────────────────────
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No complaints found.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: const Color(0xFFEEEEEE)),
                    child: DataTable(
                      showCheckboxColumn: false,
                      columnSpacing: 16,
                      horizontalMargin: 20,
                      headingRowHeight: 40,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 52,
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
                      dataTextStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                      columns: const [
                        DataColumn(label: Text('TICKET ID')),
                        DataColumn(label: Text('ITEM NAME')),
                        DataColumn(label: Text('EQUIPMENT')),
                        DataColumn(label: Text('PRIORITY')),
                        DataColumn(label: Text('STATUS')),
                      ],
                      rows: rows.map((c) {
                        final priority = _mapPriority(c.priorityLevel);
                        final status = _mapStatus(c.complaintstatus);
                        return DataRow(
                          onSelectChanged: (selected) {
                            if (selected != null) {
                              _showcomplaintform(context, c);
                            }
                          },
                          cells: [
                            DataCell(
                              Text(
                                c.ticketId,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                c.categoryName ?? '-',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 160,
                                child: Text(
                                  c.serviceRequired ?? c.problem ?? '-',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(_priorityBadge(priority)),
                            DataCell(_statusBadge(status)),
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
                      onPressed: rows.length < _pageSize ? null : _nextPage,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
//=========================================Complaint details form dialog=========================================
  void _showcomplaintform(BuildContext context, ComplaintModel c) {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Center(
          child: SizedBox(
            width: 600,
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Complaint Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _editField('Ticket ID:-', c.ticketId, Icons.numbers),
                      const SizedBox(height: 14),
                      _editField(
                        'Item Name:-',
                        c.categoryName ?? 'N/A',
                        Icons.devices_other_sharp,
                      ),
                      const SizedBox(height: 14),
                      _editField(
                        'Service Required:-',
                        c.serviceRequired ?? 'N/A',
                        Icons.business_outlined,
                      ),
                      const SizedBox(height: 14),
                      _editField(
                        'Problem:-',
                        c.problem ?? 'N/A',
                        Icons.report_problem_outlined,
                      ),
                      const SizedBox(height: 14),
                      _editField(
                        'Priority Level:-',
                        c.priorityLevel ?? 'N/A',
                        Icons.flag_outlined,
                      ),
                      const SizedBox(height: 14),
                      _editField(
                        'Status:-',
                        c.complaintstatus ?? 'N/A',
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 14),
                      _editField(
                        'Tech Assigned:-',
                        c.technicians.isNotEmpty
                            ? c.technicians.map((t) => t.name).join(', ')
                            : 'N/A',
                        Icons.person_outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
//=============================Helper widget to display a label and value with an icon in the complaint details dialog=============================
  Widget _editField(String label, String value, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
    ],
  );
}
