/// Data model and mock data for Worker Jobs and Availability
/// Strict compliance with docs/conventions.md and docs/api-contract.md (Supabase DB schema).
class WorkerJob {
  final String bookingId; // UUID (booking_id in Supabase)
  final String? serviceId; // UUID (service_id in Supabase)
  final String? workerId; // UUID (worker_id in Supabase)
  final String? customerId; // UUID (customer_id in Supabase)
  final String customerName; // customer_name / joined profiles.full_name
  final String customerPhone; // customer_phone / profiles.phone
  final String serviceName; // service_name / services.name
  final String address; // address
  final String scheduledTime; // Human readable display time
  final String? scheduledAt; // ISO 8601 UTC timestamp (scheduled_at in Supabase)
  final int amount; // in paise (integer currency unit, e.g. 45000 = ₹450)
  final String status; // 'PENDING' | 'ACCEPTED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
  final String? notes; // notes

  const WorkerJob({
    required this.bookingId,
    this.serviceId,
    this.workerId,
    this.customerId,
    required this.customerName,
    this.customerPhone = '+91 98765 43210',
    required this.serviceName,
    required this.address,
    required this.scheduledTime,
    this.scheduledAt,
    required this.amount,
    required this.status,
    this.notes,
  });

  /// Formatted payout in Rupees (e.g., ₹450)
  String get formattedAmount {
    final double rupees = amount / 100.0;
    if (rupees == rupees.roundToDouble()) {
      return '₹${rupees.toInt()}';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }

  /// Amount in Rupees as a double
  double get amountInRupees => amount / 100.0;

  /// Check if the job is still pending acceptance
  bool get isPending => status.toUpperCase() == 'PENDING';

  /// Check if the job is accepted
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';

  /// Check if the job is currently in progress
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';

  /// Check if the job is completed
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  /// Copy with modifications
  WorkerJob copyWith({
    String? bookingId,
    String? serviceId,
    String? workerId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? serviceName,
    String? address,
    String? scheduledTime,
    String? scheduledAt,
    int? amount,
    String? status,
    String? notes,
  }) {
    return WorkerJob(
      bookingId: bookingId ?? this.bookingId,
      serviceId: serviceId ?? this.serviceId,
      workerId: workerId ?? this.workerId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceName: serviceName ?? this.serviceName,
      address: address ?? this.address,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  /// Create a WorkerJob from JSON (matching API contract and Supabase schema)
  factory WorkerJob.fromJson(Map<String, dynamic> json) {
    // Extract nested service name
    String sName = 'Service';
    int sAmount = 49900;
    if (json['services'] is Map) {
      sName = json['services']['name'] ?? 'Service';
      sAmount = (json['services']['base_price_amount'] as num?)?.toInt() ?? 49900;
    } else if (json['service_name'] != null) {
      sName = json['service_name'];
    }

    // Extract nested customer name
    String cName = 'Customer';
    String cPhone = '+91 98765 43210';
    if (json['profiles'] is Map) {
      cName = json['profiles']['full_name'] ?? 'Customer';
      cPhone = json['profiles']['phone'] ?? '+91 98765 43210';
    } else if (json['customer_name'] != null) {
      cName = json['customer_name'];
    }

    // Extract time
    String sTime = 'Today, Flexible Slot';
    if (json['scheduled_at'] != null) {
      try {
        final dt = DateTime.parse(json['scheduled_at']).toLocal();
        sTime = '${dt.day}/${dt.month} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        sTime = json['scheduled_at'];
      }
    }

    return WorkerJob(
      bookingId: json['booking_id'] as String? ?? json['id'] as String? ?? '',
      serviceId: json['service_id'] as String?,
      workerId: json['worker_id'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: cName,
      customerPhone: cPhone,
      serviceName: sName,
      address: json['address'] as String? ?? 'Indiranagar, Bengaluru',
      scheduledTime: sTime,
      scheduledAt: json['scheduled_at'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? (json['base_price_amount'] as num?)?.toInt() ?? sAmount,
      status: json['status'] as String? ?? 'PENDING',
      notes: json['notes'] as String?,
    );
  }


  /// Convert WorkerJob to JSON (matching API contract and Supabase schema)
  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      if (serviceId != null) 'service_id': serviceId,
      if (workerId != null) 'worker_id': workerId,
      if (customerId != null) 'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_name': serviceName,
      'address': address,
      'scheduled_time': scheduledTime,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      'amount': amount,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Model for weekly availability slots matching GET/PUT /workers/{id}/availability
class WorkerAvailabilitySlot {
  final String dayOfWeek; // 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
  final String startTime; // '09:00'
  final String endTime; // '17:00'
  final bool isAvailable;

  const WorkerAvailabilitySlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  String get fullDayName {
    switch (dayOfWeek.toUpperCase()) {
      case 'MON':
        return 'Monday';
      case 'TUE':
        return 'Tuesday';
      case 'WED':
        return 'Wednesday';
      case 'THU':
        return 'Thursday';
      case 'FRI':
        return 'Friday';
      case 'SAT':
        return 'Saturday';
      case 'SUN':
        return 'Sunday';
      default:
        return dayOfWeek;
    }
  }

  WorkerAvailabilitySlot copyWith({
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) {
    return WorkerAvailabilitySlot(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory WorkerAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return WorkerAvailabilitySlot(
      dayOfWeek: json['day_of_week'] as String? ?? 'MON',
      startTime: json['start_time'] as String? ?? '09:00',
      endTime: json['end_time'] as String? ?? '17:00',
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    };
  }
}

/// 3 Mock incoming jobs matching Supabase schema conventions
final List<WorkerJob> mockWorkerJobs = [
  const WorkerJob(
    bookingId: '7f9a12c4-83b1-4682-a9b0-11e42f901001',
    serviceId: 'srv-101-fan-repair',
    workerId: 'wrk-501-rajesh-kumar',
    customerId: 'cust-201-aarav-sharma',
    customerName: 'Aarav Sharma',
    customerPhone: '+91 98451 22345',
    serviceName: 'Ceiling Fan & Light Repair',
    address: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru',
    scheduledTime: 'Today, 02:30 PM',
    scheduledAt: '2026-09-01T14:30:00Z',
    amount: 45000, // ₹450 (in paise)
    status: 'PENDING',
    notes: 'Fan making loud grinding noise and regulator sparking.',
  ),
  const WorkerJob(
    bookingId: '3e8d55b1-6a2c-4739-bf88-22f53e012002',
    serviceId: 'srv-102-wiring-fix',
    workerId: 'wrk-501-rajesh-kumar',
    customerId: 'cust-202-priya-patel',
    customerName: 'Priya Patel',
    customerPhone: '+91 97312 88765',
    serviceName: 'Switchboard & Heavy Wiring Fix',
    address: 'House #18, 5th Main, 100ft Road, Indiranagar, Bengaluru',
    scheduledTime: 'Today, 04:30 PM',
    scheduledAt: '2026-09-01T16:30:00Z',
    amount: 75000, // ₹750 (in paise)
    status: 'PENDING',
    notes: 'Power outlet burned out in master bedroom.',
  ),
  const WorkerJob(
    bookingId: '9a4c88e2-54d9-4821-b382-33e64f123003',
    serviceId: 'srv-103-mcb-repair',
    workerId: 'wrk-501-rajesh-kumar',
    customerId: 'cust-203-rohan-verma',
    customerName: 'Rohan Verma',
    customerPhone: '+91 96110 54321',
    serviceName: 'MCB Trip & Distribution Fuse Repair',
    address: 'B-203, Palm Grove, HSR Layout Sector 2, Bengaluru',
    scheduledTime: 'Tomorrow, 10:00 AM',
    scheduledAt: '2026-09-02T10:00:00Z',
    amount: 60000, // ₹600 (in paise)
    status: 'PENDING',
    notes: 'Main kitchen circuit breaker trips repeatedly when microwave is turned on.',
  ),
];

/// Mock weekly availability slots matching contract conventions
final List<WorkerAvailabilitySlot> mockWeeklyAvailability = [
  const WorkerAvailabilitySlot(dayOfWeek: 'MON', startTime: '09:00', endTime: '18:00', isAvailable: true),
  const WorkerAvailabilitySlot(dayOfWeek: 'TUE', startTime: '09:00', endTime: '18:00', isAvailable: true),
  const WorkerAvailabilitySlot(dayOfWeek: 'WED', startTime: '09:00', endTime: '18:00', isAvailable: true),
  const WorkerAvailabilitySlot(dayOfWeek: 'THU', startTime: '09:00', endTime: '18:00', isAvailable: true),
  const WorkerAvailabilitySlot(dayOfWeek: 'FRI', startTime: '09:00', endTime: '18:00', isAvailable: true),
  const WorkerAvailabilitySlot(dayOfWeek: 'SAT', startTime: '10:00', endTime: '16:00', isAvailable: true),
  const WorkerAvailabilitySlot(dayOfWeek: 'SUN', startTime: '10:00', endTime: '14:00', isAvailable: false),
];
