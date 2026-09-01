import 'package:flutter/material.dart';
import '../models/worker_job.dart';

/// Interactive Card displaying an incoming job request or accepted task with
/// customer address, requested service, scheduled time, payout, and action buttons.
class JobRequestCard extends StatelessWidget {
  final WorkerJob job;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onStartJob;
  final VoidCallback? onCompleteJob;

  const JobRequestCard({
    super.key,
    required this.job,
    this.onAccept,
    this.onDecline,
    this.onStartJob,
    this.onCompleteJob,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getBorderColor(),
          width: job.isAccepted ? 1.5 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Service Title & Payout Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.customerName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price / Payout Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Text(
                    job.formattedAmount,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20, color: Color(0xFFE2E8F0)),

            // Schedule / Slot Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scheduled: ${job.scheduledTime}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),

            const SizedBox(height: 10),

            // Address Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.address,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            // Notes if present
            if (job.notes != null && job.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        job.notes!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (job.status.toUpperCase()) {
      case 'ACCEPTED':
        return const Color(0xFF81C784);
      case 'IN_PROGRESS':
        return const Color(0xFF64B5F6);
      case 'PENDING':
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  Widget _buildStatusChip() {
    Color bg;
    Color text;
    String label = job.status.toUpperCase();

    switch (label) {
      case 'ACCEPTED':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        break;
      case 'IN_PROGRESS':
        bg = const Color(0xFFE3F2FD);
        text = const Color(0xFF1565C0);
        break;
      case 'COMPLETED':
        bg = const Color(0xFFF3E5F5);
        text = const Color(0xFF7B1FA2);
        break;
      case 'PENDING':
      default:
        bg = const Color(0xFFFFF8E1);
        text = const Color(0xFFF57F17);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (job.isPending) {
      return Row(
        children: [
          // Decline Button (Outlined Gray)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDecline,
              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
              label: const Text(
                'Decline',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Accept Button (Green)
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Accept',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (job.isAccepted) {
      return Row(
        children: [
          // Start Work Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStartJob,
              icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Start Job',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (job.isInProgress) {
      return Row(
        children: [
          // Complete Job Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCompleteJob,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Complete Job',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

