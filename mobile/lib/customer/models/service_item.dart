/// ServiceItem model representing customer-facing service listings.
/// Matches the API contract specification in `docs/api-contract.md`.
class ServiceItem {
  final String serviceId;
  final String name;
  final String category;
  final String description;
  final int basePriceAmount; // Stored in paise (e.g., 49900 = ₹499)
  final String imageUrl;
  final List<String> includedFeatures;
  final double ratingAvg;
  final int reviewCount;

  const ServiceItem({
    required this.serviceId,
    required this.name,
    required this.category,
    required this.description,
    required this.basePriceAmount,
    required this.imageUrl,
    this.includedFeatures = const [],
    this.ratingAvg = 4.8,
    this.reviewCount = 120,
  });

  /// Price converted to Rupees (double).
  double get priceInRupees => basePriceAmount / 100.0;

  /// Formatted price string with Rupee symbol (e.g., '₹499' or '₹499.50').
  String get formattedPrice {
    final double rupees = priceInRupees;
    if (rupees == rupees.roundToDouble()) {
      return '₹${rupees.toInt()}';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }

  /// Construct a [ServiceItem] from a JSON map matching the API contract.
  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceId: json['service_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePriceAmount: (json['base_price_amount'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      includedFeatures: json['included_features'] != null
          ? List<String>.from(json['included_features'] as List)
          : const [],
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 120,
    );
  }

  /// Serialize this [ServiceItem] to a JSON map conforming to `docs/api-contract.md`.
  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'name': name,
      'category': category,
      'description': description,
      'base_price_amount': basePriceAmount,
      'image_url': imageUrl,
      'included_features': includedFeatures,
      'rating_avg': ratingAvg,
      'review_count': reviewCount,
    };
  }

  /// Static mock fixtures of services for customer discovery.
  static const List<ServiceItem> mockServices = [
    ServiceItem(
      serviceId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      name: 'Home Deep Cleaning',
      category: 'Cleaning',
      description: 'Comprehensive deep cleaning for living room, bedrooms, kitchen, and bathrooms. Includes floor scrubbing, dusting, and sanitization.',
      basePriceAmount: 149900, // ₹1,499
      imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80',
      includedFeatures: [
        'Deep scrubbing of all hard floors & tiles',
        'Kitchen degreasing & exhaust hood cleanup',
        'Sanitization of all bathrooms & fixtures',
        'Dusting of fans, lights, cabinets & balconies',
        'Eco-friendly, chemical-safe disinfectants',
      ],
      ratingAvg: 4.9,
      reviewCount: 342,
    ),
    ServiceItem(
      serviceId: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
      name: 'AC Service & Repair',
      category: 'Appliance',
      description: 'Complete air conditioner servicing including filter cleaning, cooling coil wash, gas pressure check, and performance inspection.',
      basePriceAmount: 59900, // ₹599
      imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=800&q=80',
      includedFeatures: [
        'High-pressure jet foam cleaning of indoor & outdoor units',
        'Filter wash and air disinfectant treatment',
        'Refrigerant gas leak and pressure inspection',
        'Drain pipe unclogging to prevent water leakage',
        '30-day post-service cooling guarantee',
      ],
      ratingAvg: 4.8,
      reviewCount: 215,
    ),
    ServiceItem(
      serviceId: 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
      name: 'Plumbing Inspection & Repair',
      category: 'Plumber',
      description: 'Expert plumbing service for pipe leakage, tap installation, drain unclogging, and bathroom fittings repair.',
      basePriceAmount: 39900, // ₹399
      imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80',
      includedFeatures: [
        'Full bathroom & kitchen plumbing diagnostics',
        'Leakage detection and seal replacements',
        'Tap, flush valve & sink repair/replacement',
        'Blockage clearing using heavy-duty snake coils',
        'Genuine spare parts with warranty',
      ],
      ratingAvg: 4.7,
      reviewCount: 184,
    ),
    ServiceItem(
      serviceId: 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
      name: 'Electrician Home Service',
      category: 'Electrician',
      description: 'Certified electrician assistance for switchboard repairs, fan installation, wiring check, and appliance setup.',
      basePriceAmount: 29900, // ₹299
      imageUrl: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?auto=format&fit=crop&w=800&q=80',
      includedFeatures: [
        'Complete voltage and short-circuit diagnosis',
        'Switchboard, MCB & fuse board replacements',
        'Ceiling fan and lighting fixture installation',
        'Heavy appliance plug point wiring & earthing test',
        'Certified & insured electrical technicians',
      ],
      ratingAvg: 4.9,
      reviewCount: 298,
    ),
    ServiceItem(
      serviceId: 'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
      name: 'Pest Control Treatment',
      category: 'Pest Control',
      description: 'Safe and odorless pest control treatment for cockroaches, ants, termites, and bed bugs with long-lasting protection.',
      basePriceAmount: 89900, // ₹899
      imageUrl: 'https://images.unsplash.com/photo-1587393855524-087f83d95bc9?auto=format&fit=crop&w=800&q=80',
      includedFeatures: [
        'Targeted gel and spray application in hidden corners',
        'Odorless and government-approved safe chemicals',
        'Kitchen drain baiting for cockroach eradication',
        'Free follow-up inspection within 45 days',
        'Safe for pets, infants, and seniors',
      ],
      ratingAvg: 4.8,
      reviewCount: 167,
    ),
  ];
}
