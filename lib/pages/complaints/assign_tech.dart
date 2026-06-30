import 'package:field_star/model/tech_model.dart';
import 'package:field_star/repository/technician_repository.dart';
import 'package:flutter/material.dart';

class TechnicianOption {
  final String initials;
  final String id;
  final Color avatarColor;
  final String name;
  final String techId;
  final String location;
  final bool isAvailable;
  final int activeJobs;

  const TechnicianOption({
    required this.initials,
    required this.avatarColor,
    required this.name,
    required this.techId,
    required this.location,
    required this.isAvailable,
    required this.activeJobs,
    required this.id,
  });
}

class AssignTechnicianDialog extends StatefulWidget {
  final String ticketId;
  // ← changed: now passes a List instead of a single item
  final Future<void> Function(List<TechnicianOption> selected) onAssign;

  const AssignTechnicianDialog({
    super.key,
    required this.ticketId,
    required this.onAssign,
  });

  @override
  State<AssignTechnicianDialog> createState() => _AssignTechnicianDialogState();
}

class _AssignTechnicianDialogState extends State<AssignTechnicianDialog> {
  final Set<String> _selectedIds = {};
  final Map<String, TechnicianOption> _selectedOptions = {};

  late Future<List<TechModel>> _techFuture;
  final TechnicianRepository _repo = TechnicianRepository();
  bool _isAssigning = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _techFuture = _repo.fetchTechnicians();
  }

  List<TechModel> _applySearch(List<TechModel> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where(
          (c) =>
              c.fullName.toLowerCase().contains(q) ||
              c.techId.toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleSelection(TechnicianOption option) {
    setState(() {
      if (_selectedIds.contains(option.id)) {
        _selectedIds.remove(option.id);
        _selectedOptions.remove(option.id);
      } else {
        _selectedIds.add(option.id);
        _selectedOptions[option.id] = option;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: SizedBox(
        width: 400,
        height: 520,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              const Text(
                'Assign Technicians',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select one or more technicians for ${widget.ticketId}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),

              // ── Selected chips row ───────────────────────────────
              if (_selectedIds.isNotEmpty) ...[
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final option = _selectedOptions.values.elementAt(index);
                      return Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFFFF4EC),
                        side: const BorderSide(color: Color(0xFFE8680A)),
                        label: Text(
                          option.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE8680A),
                          ),
                        ),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFFE8680A),
                        ),
                        onDeleted: () => _toggleSelection(option),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // ── Search box ───────────────────────────────────────
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase().trim()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or tech ID...',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
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
              const SizedBox(height: 12),

              // ── Technician list ──────────────────────────────────
              Expanded(
                child: FutureBuilder<List<TechModel>>(
                  future: _techFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    final rows = _applySearch(snapshot.data ?? []);

                    if (rows.isEmpty) {
                      return const Center(
                        child: Text(
                          'No technicians found',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final tech = rows[index];
                        final option = TechnicianOption(
                          initials: getInitials(tech.fullName),
                          avatarColor: Colors.blue,
                          name: tech.fullName,
                          techId: tech.techId,
                          location: tech.location,
                          isAvailable: true,
                          activeJobs: 0,
                          id: tech.id ?? '',
                        );
                        return _buildTechnicianTile(option);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // ── Action buttons ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedIds.isEmpty || _isAssigning
                          ? null
                          : () async {
                              setState(() => _isAssigning = true);
                              await widget.onAssign(
                                _selectedOptions.values.toList(),
                              );
                              if (!mounted) return;
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8680A),
                        disabledBackgroundColor: const Color(
                          0xFFE8680A,
                        ).withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isAssigning
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              // ← shows count when >1 selected
                              _selectedIds.length > 1
                                  ? 'Assign (${_selectedIds.length})'
                                  : 'Assign',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianTile(TechnicianOption tech) {
    final isSelected = _selectedIds.contains(tech.id);

    return GestureDetector(
      onTap: () => _toggleSelection(tech),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE8680A)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: tech.avatarColor,
              child: Text(
                tech.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tech.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${tech.techId} • ${tech.location}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // ← checkmark badge replaces the implicit "highlighted = selected" cue
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8680A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  String getInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return '?';
    final words = cleanName.split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return cleanName.length >= 2
        ? cleanName.substring(0, 2).toUpperCase()
        : cleanName[0].toUpperCase();
  }
}
