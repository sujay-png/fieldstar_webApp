import 'package:field_star/component/stat_card.dart';
import 'package:field_star/navigation/primaryscaffold.dart';
import 'package:field_star/pages/overview/recenttranscation.dart';
import 'package:field_star/repository/technician_repository.dart';
import 'package:flutter/material.dart';

class Overview extends StatefulWidget {
  final String technicianId;

  const Overview({super.key, required this.technicianId});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  final repo = TechnicianRepository();
  late Future<Map<String, dynamic>> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = repo.fetchDashboardStats(widget.technicianId);
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      dashboardFuture = repo.fetchDashboardStats(widget.technicianId);
    });
    await dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return sidebar(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Welcome back! Here's what's happening today.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshDashboard,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              //=======================Fetch dashboard kpiboxes count============================================
              FutureBuilder<Map<String, dynamic>>(
                future: dashboardFuture,
                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Error
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Failed to load stats: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  // No data guard
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 100);
                  }

                  final data = snapshot.data!;

                  // Safe casting with fallback defaults
                  final activeComplaints =
                      (data['activeComplaints'] as num?)?.toInt() ?? 0;
                  final completedToday =
                      (data['completedToday'] as num?)?.toInt() ?? 0;
                  final activeTechs =
                      (data['activeTechnicians'] as num?)?.toInt() ?? 0;
                  final pendingComplaints =
                      (data['pendingComplaints'] as num?)?.toInt() ?? 0;
                  final completedComplaints =
                      (data['completedComplaints'] as num?)?.toInt() ?? 0;

                  return Row(
                    children: [
                      // ── Active Complaints ─────────────────────────────────────────────
                      Expanded(
                        child: StatCard(
                          value: '$activeComplaints',
                          label: 'Active Complaints',
                          icon: Icons.warning,
                          iconBackgroundColor: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Completed Today ───────────────────────────────────────────────
                      Expanded(
                        child: StatCard(
                          value: '$completedToday',
                          label: 'Completed Today',
                          icon: Icons.done_all_outlined,
                          iconBackgroundColor: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Active Technicians ────────────────────────────────────────────
                      Expanded(
                        child: StatCard(
                          value: '$activeTechs',
                          label: 'Active Technicians',
                          icon: Icons.people,
                          iconBackgroundColor: Colors.purpleAccent,
                          trendColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Pending Complaints ────────────────────────────────────────────
                      Expanded(
                        child: StatCard(
                          value: '$pendingComplaints',
                          label: 'Pending Complaints',
                          icon: Icons.pending_actions,
                          iconBackgroundColor: Colors.amber,
                          trendColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Completed Complaints ──────────────────────────────────────────
                      Expanded(
                        child: StatCard(
                          value: '$completedComplaints',
                          label: 'Completed Complaints',
                          icon: Icons.check_circle,
                          iconBackgroundColor: Colors.green,
                          trendColor: Colors.red,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Recent complaints table
              RecentComplaintsTable(
                searchQuery: '',
                onViewAll: () {
                  // Navigate to complaints page
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
