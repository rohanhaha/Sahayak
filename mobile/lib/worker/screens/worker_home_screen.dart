import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../shared/api_client.dart';
import '../../shared/auth_service.dart';
import '../models/worker_job.dart';
import '../widgets/worker_header.dart';
import '../widgets/job_request_card.dart';

/// Main Dashboard and Operations Screen for Workers
class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Worker Profile & Operations State
  String _workerName = 'Worker';
  bool _isOnDuty = true;
  int _todayEarnings = 120000; // in paise = ₹1,200
  int _completedJobsCount = 4;
  List<WorkerJob> _jobs = [];
  List<WorkerAvailabilitySlot> _availabilitySlots = [];
  bool _isLoadingJobs = true;

  // Filter for jobs tab: 'ALL' | 'PENDING' | 'ACCEPTED'
  String _selectedJobFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _jobs = List.from(mockWorkerJobs);
    _availabilitySlots = List.from(mockWeeklyAvailability);
    _loadWorkerProfile();
    _fetchLiveBookings();
  }

  Future<void> _loadWorkerProfile() async {
    final name = await AuthService.getUserName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _workerName = name;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> _fetchLiveBookings() async {
    setState(() => _isLoadingJobs = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/bookings?limit=50'),
        headers: ApiConfig.headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        final parsed = results.map((item) => WorkerJob.fromJson(item)).toList();

        setState(() {
          _jobs = parsed.isNotEmpty ? parsed : List.from(mockWorkerJobs);
          _isLoadingJobs = false;
        });
      } else {
        setState(() => _isLoadingJobs = false);
      }
    } catch (_) {
      setState(() => _isLoadingJobs = false);
    }
  }

  int get _pendingCount => _jobs.where((j) => j.isPending).length;

  String get _formattedTodayEarnings {
    final double rupees = _todayEarnings / 100.0;
    return '₹${rupees.toInt()}';
  }

  void _toggleDuty(bool value) {
    setState(() {
      _isOnDuty = value;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isOnDuty ? Icons.check_circle : Icons.pause_circle_filled,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isOnDuty ? 'You are now Online & On Duty' : 'You are now Offline (Off Duty)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: _isOnDuty ? const Color(0xFF1E7E34) : const Color(0xFF495057),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleAcceptJob(WorkerJob job) async {
    setState(() {
      final index = _jobs.indexWhere((j) => j.bookingId == job.bookingId);
      if (index != -1) {
        _jobs[index] = _jobs[index].copyWith(status: 'ACCEPTED');
      }
    });

    try {
      final token = await AuthService.getToken();
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/bookings/${job.bookingId}/status'),
        headers: ApiConfig.headers(token),
        body: jsonEncode({'status': 'ACCEPTED'}),
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Accepted: ${job.serviceName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Customer ${job.customerName} has been notified.',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleDeclineJob(WorkerJob job) async {
    setState(() {
      _jobs.removeWhere((j) => j.bookingId == job.bookingId);
    });

    try {
      final token = await AuthService.getToken();
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/bookings/${job.bookingId}/status'),
        headers: ApiConfig.headers(token),
        body: jsonEncode({'status': 'CANCELLED'}),
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Declined job request from ${job.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF616161),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleStartJob(WorkerJob job) async {
    setState(() {
      final index = _jobs.indexWhere((j) => j.bookingId == job.bookingId);
      if (index != -1) {
        _jobs[index] = _jobs[index].copyWith(status: 'IN_PROGRESS');
      }
    });

    try {
      final token = await AuthService.getToken();
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/bookings/${job.bookingId}/status'),
        headers: ApiConfig.headers(token),
        body: jsonEncode({'status': 'IN_PROGRESS'}),
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job for ${job.customerName} is now In Progress.'),
        backgroundColor: const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleCompleteJob(WorkerJob job) async {
    setState(() {
      final index = _jobs.indexWhere((j) => j.bookingId == job.bookingId);
      if (index != -1) {
        _jobs[index] = _jobs[index].copyWith(status: 'COMPLETED');
        _todayEarnings += job.amount;
        _completedJobsCount += 1;
      }
    });

    try {
      final token = await AuthService.getToken();
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/bookings/${job.bookingId}/status'),
        headers: ApiConfig.headers(token),
        body: jsonEncode({'status': 'COMPLETED'}),
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job completed! ${job.formattedAmount} added to Today\'s Earnings.'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _toggleAvailabilitySlot(int index, bool value) {
    setState(() {
      _availabilitySlots[index] = _availabilitySlots[index].copyWith(isAvailable: value);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_availabilitySlots[index].fullDayName} availability ${value ? "enabled" : "disabled"}',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<WorkerJob> get _filteredJobs {
    switch (_selectedJobFilter) {
      case 'PENDING':
        return _jobs.where((j) => j.isPending).toList();
      case 'ACCEPTED':
        return _jobs.where((j) => j.isAccepted || j.isInProgress).toList();
      case 'ALL':
      default:
        return _jobs;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: WorkerHeader(
                workerName: _workerName,
                profession: 'Electrician',
                rating: 4.8,
                totalReviews: 124,
                isOnDuty: _isOnDuty,
                onDutyChanged: _toggleDuty,
                todayEarnings: _formattedTodayEarnings,
                completedJobsCount: _completedJobsCount,
                pendingRequestsCount: _pendingCount,
                onLogout: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out of the Worker Portal?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && context.mounted) {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  }
                },
              ),

            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1E293B),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF1E7E34),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_outlined, size: 18),
                          const SizedBox(width: 6),
                          const Text('Incoming Jobs'),
                          if (_pendingCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE65100),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_pendingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text('Weekly Availability'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildJobsTabView(),
            _buildWeeklyAvailabilityTabView(),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsTabView() {
    return CustomScrollView(
      slivers: [
        // Off-duty notice if worker is offline
        if (!_isOnDuty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF856404), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are currently Off Duty. Switch to Online at the top to receive real-time customer requests.',
                      style: TextStyle(
                        color: Color(0xFF856404),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Filter chips bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Jobs (${_jobs.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING', 'Pending ($_pendingCount)'),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'ACCEPTED',
                  'Active (${_jobs.where((j) => j.isAccepted || j.isInProgress).length})',
                ),
              ],
            ),
          ),
        ),

        // Job items list or empty state
        if (_filteredJobs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedJobFilter == 'PENDING'
                          ? 'No pending requests at the moment'
                          : 'No jobs found in this section',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isOnDuty
                          ? 'Stay online. New customer requests will appear here.'
                          : 'Turn on duty toggle to receive bookings.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final job = _filteredJobs[index];
                return JobRequestCard(
                  job: job,
                  onAccept: () => _handleAcceptJob(job),
                  onDecline: () => _handleDeclineJob(job),
                  onStartJob: () => _handleStartJob(job),
                  onCompleteJob: () => _handleCompleteJob(job),
                );
              },
              childCount: _filteredJobs.length,
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final bool isSelected = _selectedJobFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedJobFilter = filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyAvailabilityTabView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule, color: Color(0xFF1E7E34), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Working Schedule & Hours',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Configure which days you are open to take customer repair bookings matching your contract preferences.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _availabilitySlots.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final slot = _availabilitySlots[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: slot.isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              slot.dayOfWeek,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: slot.isAvailable ? const Color(0xFF2E7D32) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.fullDayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: slot.isAvailable ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  slot.isAvailable ? '${slot.startTime} - ${slot.endTime}' : 'Unavailable / Day Off',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: slot.isAvailable ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: slot.isAvailable,
                            onChanged: (val) => _toggleAvailabilitySlot(index, val),
                            activeColor: const Color(0xFF1E7E34),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Availability slots sync with the matching algorithm to distribute customer leads during your active hours.',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

/// Helper Sliver Header delegate for pinned TabBar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}

