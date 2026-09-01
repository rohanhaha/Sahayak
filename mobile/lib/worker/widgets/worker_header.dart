import 'package:flutter/material.dart';

/// Worker Header Widget displaying profile summary, online/duty switch,
/// and quick operational metric cards.
class WorkerHeader extends StatelessWidget {
  final String workerName;
  final String profession;
  final double rating;
  final int totalReviews;
  final bool isOnDuty;
  final ValueChanged<bool> onDutyChanged;
  final String todayEarnings;
  final int completedJobsCount;
  final int pendingRequestsCount;
  final VoidCallback? onLogout;

  const WorkerHeader({
    super.key,
    this.workerName = 'Rajesh Kumar',
    this.profession = 'Electrician',
    this.rating = 4.8,
    this.totalReviews = 124,
    required this.isOnDuty,
    required this.onDutyChanged,
    this.todayEarnings = '₹1,200',
    this.completedJobsCount = 4,
    this.pendingRequestsCount = 2,
    this.onLogout,
  });


  @override
  Widget build(BuildContext context) {
    // Dynamic theme colors based on duty status
    final Color headerColor = isOnDuty ? const Color(0xFF1E7E34) : const Color(0xFF5A6268);
    final Color badgeBg = isOnDuty ? const Color(0xFF155724) : const Color(0xFF383D41);

    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: headerColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Avatar, Info, and Duty Switch
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Avatar with Status Indicator
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(
                            Icons.person,
                            size: 34,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isOnDuty ? const Color(0xFF28A745) : Colors.grey.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Name, Profession, and Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$workerName - $profession',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Color(0xFFFFC107),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($totalReviews jobs)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Duty Toggle Switch with Animated Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOnDuty ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: isOnDuty ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: isOnDuty,
                            onChanged: onDutyChanged,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF81C784),
                            inactiveThumbColor: Colors.white70,
                            inactiveTrackColor: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onLogout != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      tooltip: 'Log Out',
                      onPressed: onLogout,
                    ),
                  ],
                ],
              ),


              const SizedBox(height: 20),

              // Duty status indicator subtitle banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnDuty ? Icons.check_circle_outline : Icons.pause_circle_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isOnDuty
                            ? 'You are On Duty and visible to receive new bookings nearby'
                            : 'You are Off Duty. Toggle switch to start accepting customer jobs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3 Quick Summary Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.currency_rupee,
                      iconColor: const Color(0xFF2E7D32),
                      title: "Today's Earnings",
                      value: todayEarnings,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.task_alt,
                      iconColor: const Color(0xFF1976D2),
                      title: 'Completed',
                      value: '$completedJobsCount',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.pending_actions,
                      iconColor: const Color(0xFFE65100),
                      title: 'Pending',
                      value: '$pendingRequestsCount',
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

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212529),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

