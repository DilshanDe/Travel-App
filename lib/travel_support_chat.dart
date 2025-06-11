import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class TravelSupportScreen extends StatefulWidget {
  const TravelSupportScreen({super.key});

  @override
  State<TravelSupportScreen> createState() => _TravelSupportScreenState();
}

class _TravelSupportScreenState extends State<TravelSupportScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isTyping = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _destinationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Get current user
  User? get currentUser => FirebaseAuth.instance.currentUser;
  String get currentUserId => currentUser?.uid ?? 'anonymous_user';

  // Enhanced quick actions with Sri Lankan destinations
  final List<Map<String, dynamic>> _quickActions = [
    {
      "text": "Hello! I need travel help",
      "icon": Icons.waving_hand,
      "color": Colors.orange
    },
    {
      "text": "Find flights to Colombo",
      "icon": Icons.flight,
      "color": Colors.blue
    },
    {
      "text": "Best hotels in Kandy",
      "icon": Icons.hotel,
      "color": Colors.green
    },
    {"text": "Day tours in Galle", "icon": Icons.tour, "color": Colors.purple},
    {
      "text": "Trincomalee beaches",
      "icon": Icons.beach_access,
      "color": Colors.cyan
    },
    {
      "text": "Jaffna cultural sites",
      "icon": Icons.temple_hindu,
      "color": Colors.amber
    },
    {
      "text": "Matale spice gardens",
      "icon": Icons.local_florist,
      "color": Colors.pink
    },
    {
      "text": "Weather forecast",
      "icon": Icons.wb_sunny,
      "color": Colors.orange
    },
    {
      "text": "Need taxi/transport",
      "icon": Icons.local_taxi,
      "color": Colors.indigo
    },
    {
      "text": "Travel requirements",
      "icon": Icons.assignment,
      "color": Colors.red
    },
  ];

  // Sri Lankan destinations database
  final Map<String, Map<String, dynamic>> _sriLankanDestinations = {
    "trincomalee": {
      "name": "Trincomalee",
      "province": "Eastern Province",
      "highlights": [
        "Nilaveli Beach",
        "Pigeon Island",
        "Koneswaram Temple",
        "Hot Springs"
      ],
      "bestTime": "May to September",
      "activities": [
        "Snorkeling",
        "Whale watching",
        "Temple visits",
        "Beach relaxation"
      ],
      "hotels": [
        "Jungle Beach by Uga Escapes",
        "Trinco Blu by Cinnamon",
        "Club Oceanic"
      ],
      "transport": "3-hour drive from Colombo, domestic flights available",
      "taxiApps": ["PickMe", "Uber (limited)"],
    },
    "galle": {
      "name": "Galle",
      "province": "Southern Province",
      "highlights": [
        "Galle Fort",
        "Unawatuna Beach",
        "Dutch Reformed Church",
        "Lighthouse"
      ],
      "bestTime": "December to March",
      "activities": [
        "Fort exploration",
        "Whale watching",
        "Surfing",
        "Shopping"
      ],
      "hotels": ["Amangalla", "Jetwing Lighthouse", "Fort Printers"],
      "transport": "2-hour drive from Colombo, train available",
      "taxiApps": ["PickMe", "Uber"],
    },
    "jaffna": {
      "name": "Jaffna",
      "province": "Northern Province",
      "highlights": [
        "Jaffna Fort",
        "Nallur Temple",
        "Casuarina Beach",
        "Palmyra Palm"
      ],
      "bestTime": "December to March",
      "activities": [
        "Cultural tours",
        "Temple visits",
        "Island hopping",
        "Local cuisine"
      ],
      "hotels": [
        "Jetwing Jaffna",
        "Green Grass Hotel",
        "Tilko Jaffna City Hotel"
      ],
      "transport": "8-hour drive from Colombo, domestic flights available",
      "taxiApps": ["PickMe", "Local taxis"],
    },
    "matale": {
      "name": "Matale",
      "province": "Central Province",
      "highlights": [
        "Spice Gardens",
        "Aluvihare Temple",
        "Sembuwatta Lake",
        "Riverston"
      ],
      "bestTime": "January to March, July to September",
      "activities": [
        "Spice tours",
        "Hiking",
        "Temple visits",
        "Lake activities"
      ],
      "hotels": ["Santani Resort", "Rangala House", "Heritage Kandalama"],
      "transport": "2.5-hour drive from Colombo",
      "taxiApps": ["PickMe", "Uber (limited)"],
    },
    "kandy": {
      "name": "Kandy",
      "province": "Central Province",
      "highlights": [
        "Temple of Tooth",
        "Peradeniya Gardens",
        "Kandy Lake",
        "Cultural Shows"
      ],
      "bestTime": "December to April",
      "activities": [
        "Temple visits",
        "Cultural shows",
        "Botanical gardens",
        "City walks"
      ],
      "hotels": ["The Kandy House", "Earl's Regency", "Hotel Suisse"],
      "transport": "3-hour drive from Colombo, train available",
      "taxiApps": ["PickMe", "Uber"],
    },
    "ella": {
      "name": "Ella",
      "province": "Uva Province",
      "highlights": [
        "Nine Arch Bridge",
        "Little Adam's Peak",
        "Ella Rock",
        "Tea Plantations"
      ],
      "bestTime": "December to March, July to September",
      "activities": [
        "Hiking",
        "Train rides",
        "Tea factory visits",
        "Photography"
      ],
      "hotels": ["98 Acres Resort", "Ella Jungle Resort", "Tea Garden Hotel"],
      "transport": "6-hour drive from Colombo, scenic train available",
      "taxiApps": ["PickMe", "Local taxis"],
    },
    "sigiriya": {
      "name": "Sigiriya",
      "province": "Central Province",
      "highlights": [
        "Sigiriya Rock",
        "Pidurangala Rock",
        "Dambulla Cave Temple",
        "Village Tours"
      ],
      "bestTime": "January to March, July to September",
      "activities": [
        "Rock climbing",
        "Cave exploration",
        "Village tours",
        "Cycling"
      ],
      "hotels": [
        "Heritance Kandalama",
        "Sigiriya Village Hotel",
        "Hotel Sigiriya"
      ],
      "transport": "4-hour drive from Colombo",
      "taxiApps": ["PickMe", "Local taxis"],
    },
    "nuwara_eliya": {
      "name": "Nuwara Eliya",
      "province": "Central Province",
      "highlights": [
        "Gregory Lake",
        "Tea Plantations",
        "Horton Plains",
        "Victoria Park"
      ],
      "bestTime": "January to March, July to September",
      "activities": ["Tea plantation tours", "Hiking", "Boat rides", "Golf"],
      "hotels": ["Grand Hotel", "Heritance Tea Factory", "The Hill Club"],
      "transport": "4-hour drive from Colombo",
      "taxiApps": ["PickMe", "Local taxis"],
    },
    "arugam_bay": {
      "name": "Arugam Bay",
      "province": "Eastern Province",
      "highlights": [
        "Surfing Beach",
        "Pottuvil Point",
        "Kumana National Park",
        "Lighthouse"
      ],
      "bestTime": "May to September",
      "activities": [
        "Surfing",
        "Wildlife safari",
        "Beach activities",
        "Fishing"
      ],
      "hotels": [
        "Kottukal Beach House",
        "Jetwing Surf",
        "Stardust Beach Hotel"
      ],
      "transport": "6-hour drive from Colombo",
      "taxiApps": ["PickMe", "Local taxis"],
    },
    "anuradhapura": {
      "name": "Anuradhapura",
      "province": "North Central Province",
      "highlights": [
        "Sacred Bodhi Tree",
        "Ruwanwelisaya",
        "Jetavanaramaya",
        "Ancient Ruins"
      ],
      "bestTime": "December to March",
      "activities": [
        "Archaeological tours",
        "Temple visits",
        "Cycling",
        "Photography"
      ],
      "hotels": [
        "Ulagalla Resort",
        "Lakeside at Nuwarawewa",
        "Milano Tourist Rest"
      ],
      "transport": "4-hour drive from Colombo",
      "taxiApps": ["PickMe", "Local taxis"],
    }
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _destinationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _destinationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _destinationController.forward();
    _inputController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _fadeController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isCurrentlyTyping = _inputController.text.trim().isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });
    }
  }

  // Enhanced taxi service integration
  Future<void> _launchTaxiApp(String destination, String app) async {
    try {
      String url;
      String fallbackUrl;

      if (app.toLowerCase() == 'pickme') {
        // PickMe deep link
        url = 'pickme://ride?destination=${Uri.encodeComponent(destination)}';
        fallbackUrl =
            'https://play.google.com/store/apps/details?id=lk.pickme.passenger';
      } else {
        // Uber deep link
        url = 'uber://ride?destination=${Uri.encodeComponent(destination)}';
        fallbackUrl =
            'https://play.google.com/store/apps/details?id=com.ubercab';
      }

      final Uri uri = Uri.parse(url);
      final Uri fallbackUri = Uri.parse(fallbackUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        _showSnackBar("Opening $app for ride to $destination", Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Could not open $app. Please install the app first.",
            Colors.orange);
      }
    }
  }

  // Show taxi options dialog
  void _showTaxiOptions(String destination) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Get a Ride to $destination",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTaxiOption(
                        "PickMe",
                        Icons.local_taxi,
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          _launchTaxiApp(destination, "pickme");
                        },
                      ),
                      _buildTaxiOption(
                        "Uber",
                        Icons.directions_car,
                        Colors.black,
                        () {
                          Navigator.pop(context);
                          _launchTaxiApp(destination, "uber");
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Choose your preferred ride service",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxiOption(
      String name, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendQueryToDatabase(String userInput) async {
    if (userInput.trim().isEmpty) return;

    if (currentUser == null) {
      _showSnackBar("Please log in to send messages", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final category = _categorizeQuery(userInput);
      final autoReply = _getAutoReply(userInput, category);

      DocumentReference docRef =
          await _firestore.collection('travel_queries').add({
        'query': userInput.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'reply': "",
        'status': 'pending',
        'userId': currentUserId,
        'userEmail': currentUser?.email ?? 'anonymous@example.com',
        'category': category,
        'hasAutoReply': autoReply != null,
      });

      _inputController.clear();
      _scrollToBottom();

      _showSnackBar("Message sent successfully!", Colors.green);
      HapticFeedback.lightImpact();

      if (autoReply != null) {
        _sendAutoReply(docRef, autoReply);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to send message. Please try again.";
      });
      _showSnackBar("Error: ${e.toString()}", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendAutoReply(
      DocumentReference docRef, String autoReply) async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      await docRef.update({
        'reply': autoReply,
        'status': 'answered',
        'autoReplyTimestamp': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error sending auto-reply: $e");
    }
  }

  String? _getAutoReply(String query, String category) {
    final lowercaseQuery = query.toLowerCase();

    // Enhanced destination-specific replies
    for (String destination in _sriLankanDestinations.keys) {
      if (lowercaseQuery.contains(destination.replaceAll('_', ' ')) ||
          lowercaseQuery.contains(
              _sriLankanDestinations[destination]!['name'].toLowerCase())) {
        return _getDestinationInfo(destination);
      }
    }

    // Transportation and taxi queries
    if (lowercaseQuery.contains('taxi') ||
        lowercaseQuery.contains('transport') ||
        lowercaseQuery.contains('uber') ||
        lowercaseQuery.contains('pickme') ||
        lowercaseQuery.contains('ride')) {
      return "🚖 Transportation in Sri Lanka:\n\n" +
          "📱 **Ride Apps Available:**\n" +
          "🔹 PickMe - Most popular, island-wide coverage\n" +
          "🔹 Uber - Available in Colombo and major cities\n" +
          "🔹 Kangaroo Cabs - Local service\n\n" +
          "🚌 **Other Options:**\n" +
          "🔹 Three-wheelers (Tuk-tuks)\n" +
          "🔹 Buses (intercity and local)\n" +
          "🔹 Trains (scenic routes available)\n" +
          "🔹 Car rentals with driver\n\n" +
          "💡 **Tip:** Use the taxi button 🚕 next to destination info to book instantly!\n\n" +
          "Which destination do you need transport to?";
    }

    // Flight related queries
    if (category == 'flights') {
      if (lowercaseQuery.contains('colombo')) {
        return "✈️ **Flights to Colombo (CMB):**\n\n" +
            "🔹 **Airlines:** SriLankan, Emirates, Qatar, Singapore\n" +
            "🔹 **Average Price:** \$300-800 (varies by origin)\n" +
            "🔹 **Flight Time:** 8-12 hours from Europe\n" +
            "🔹 **Best Booking:** 2-3 months in advance\n" +
            "🔹 **Peak Season:** Dec-Mar, Jul-Aug\n\n" +
            "🚖 **Airport Transfer:** PickMe/Uber available\n" +
            "📍 **Distance to City:** 32km (45-60 minutes)\n\n" +
            "Need taxi booking to/from airport?";
      }

      return "✈️ **Sri Lanka Flight Guide:**\n\n" +
          "🔹 **Main Airport:** Bandaranaike International (CMB)\n" +
          "🔹 **Domestic:** Cinnamon Air, Helitours\n" +
          "🔹 **Budget Airlines:** AirAsia, Scoot\n" +
          "🔹 **Best Booking Time:** 2-3 months ahead\n\n" +
          "Which destination were you looking for?";
    }

    // Hotel related queries
    if (category == 'hotels') {
      return "🏨 **Sri Lanka Accommodation Guide:**\n\n" +
          "⭐ **Luxury Chains:**\n" +
          "🔹 Shangri-La, Cinnamon Hotels\n" +
          "🔹 Jetwing, Heritance Resorts\n" +
          "🔹 Aman, Uga Escapes\n\n" +
          "⭐ **Mid-Range:**\n" +
          "🔹 Clock Inn, Oak Ray Hotels\n" +
          "🔹 Local boutique hotels\n\n" +
          "⭐ **Budget:**\n" +
          "🔹 Backpack Lanka hostels\n" +
          "🔹 Guest houses, homestays\n\n" +
          "🚖 **Transport:** All hotels accessible via PickMe/Uber\n\n" +
          "Which city/area interests you?";
    }

    // Weather queries
    if (category == 'weather') {
      return "🌤️ **Sri Lanka Weather Guide:**\n\n" +
          "**🏖️ West/South Coast:**\n" +
          "🔹 Dry: December - March\n" +
          "🔹 Wet: May - September\n\n" +
          "**🏖️ East Coast:**\n" +
          "🔹 Dry: May - September  \n" +
          "🔹 Wet: October - January\n\n" +
          "**🏔️ Hill Country:**\n" +
          "🔹 Cool: 15-20°C year-round\n" +
          "🔹 Best: January-March, July-September\n\n" +
          "**🌡️ Temperature:** 25-30°C (coastal)\n" +
          "**🌧️ Monsoons:** Predictable patterns\n\n" +
          "Planning a specific time? Let me know!";
    }

    // Visa and requirements
    if (category == 'requirements') {
      return "📋 **Sri Lanka Travel Requirements:**\n\n" +
          "🛂 **Visa (ETA):**\n" +
          "🔹 Apply online: eta.gov.lk\n" +
          "🔹 Cost: \$20-35 USD\n" +
          "🔹 Valid: 30 days\n" +
          "🔹 Multiple entry available\n\n" +
          "💉 **Health:**\n" +
          "🔹 No mandatory vaccinations\n" +
          "🔹 Recommended: Hepatitis A/B, Typhoid\n" +
          "🔹 Dengue precautions advised\n\n" +
          "💰 **Currency:** Sri Lankan Rupee (LKR)\n" +
          "📱 **SIM Cards:** Available at airport\n" +
          "🚖 **Transport Apps:** PickMe, Uber work everywhere";
    }

    // Greetings
    if (lowercaseQuery.contains('hello') ||
        lowercaseQuery.contains('hi') ||
        lowercaseQuery.contains('good morning') ||
        lowercaseQuery.contains('good afternoon')) {
      return "👋 **Ayubowan! Welcome to Sri Lanka Travel Support!**\n\n" +
          "I'm your AI travel assistant for the beautiful island of Sri Lanka! 🇱🇰\n\n" +
          "**🗺️ I can help with:**\n" +
          "🔹 **Destinations:** Trincomalee, Galle, Jaffna, Matale, Kandy, Ella\n" +
          "🔹 **Transport:** PickMe/Uber taxi booking\n" +
          "🔹 **Hotels:** Luxury to budget accommodation\n" +
          "🔹 **Activities:** Tours, beaches, culture, wildlife\n" +
          "🔹 **Practical:** Weather, visas, currency\n\n" +
          "**🚖 Quick Taxi Booking:** Mention any destination + 'taxi'\n\n" +
          "Where would you like to explore in Sri Lanka? 🌴";
    }

    // Thank you responses
    if (lowercaseQuery.contains('thank') || lowercaseQuery.contains('thanks')) {
      return "🙏 **You're most welcome!**\n\n" +
          "I'm delighted to help you discover Sri Lanka! 🇱🇰✨\n\n" +
          "**🎯 Quick Tips:**\n" +
          "🔹 Download PickMe app for easy transport\n" +
          "🔹 Try local cuisine - rice & curry is amazing!\n" +
          "🔹 Respect local customs at temples\n" +
          "🔹 Bargain politely at markets\n\n" +
          "**📱 Stay Connected:**\n" +
          "🔹 Get local SIM at airport\n" +
          "🔹 WiFi available in most hotels\n\n" +
          "Have an incredible Sri Lankan adventure! 🌺";
    }

    // Default for complex queries
    if (query.length > 50) {
      return "📝 **Thank you for your detailed inquiry!**\n\n" +
          "Our travel experts will provide comprehensive information within 30 minutes during business hours (9 AM - 8 PM Sri Lanka time).\n\n" +
          "**🚀 For Instant Help, try:**\n" +
          "🔹 'Kandy hotels' - Accommodation options\n" +
          "🔹 'Galle taxi' - Transport booking\n" +
          "🔹 'Trincomalee beaches' - Destination info\n" +
          "🔹 'Weather December' - Climate info\n" +
          "🔹 'Jaffna culture' - Cultural attractions\n\n" +
          "**📍 Popular Destinations:** Trincomalee, Galle, Jaffna, Matale, Kandy, Ella, Sigiriya, Nuwara Eliya, Arugam Bay";
    }

    return null;
  }

  String _getDestinationInfo(String destination) {
    final info = _sriLankanDestinations[destination]!;
    return "🏖️ **${info['name']}, ${info['province']}**\n\n" +
        "**✨ Highlights:**\n" +
        "${(info['highlights'] as List).map((h) => '🔹 $h').join('\n')}\n\n" +
        "**🗓️ Best Time:** ${info['bestTime']}\n\n" +
        "**🎯 Top Activities:**\n" +
        "${(info['activities'] as List).map((a) => '🔸 $a').join('\n')}\n\n" +
        "**🏨 Recommended Hotels:**\n" +
        "${(info['hotels'] as List).map((h) => '🏨 $h').join('\n')}\n\n" +
        "**🚗 Getting There:** ${info['transport']}\n\n" +
        "**🚖 Taxi Apps:** ${(info['taxiApps'] as List).join(', ')}\n\n" +
        "💡 **Want a taxi to ${info['name']}?** Just say 'taxi to ${info['name']}' or use quick actions! 🚕";
  }

  String _categorizeQuery(String query) {
    final lowercaseQuery = query.toLowerCase();
    if (lowercaseQuery.contains('flight') ||
        lowercaseQuery.contains('airline')) {
      return 'flights';
    } else if (lowercaseQuery.contains('hotel') ||
        lowercaseQuery.contains('accommodation')) {
      return 'hotels';
    } else if (lowercaseQuery.contains('tour') ||
        lowercaseQuery.contains('activity')) {
      return 'tours';
    } else if (lowercaseQuery.contains('weather') ||
        lowercaseQuery.contains('climate')) {
      return 'weather';
    } else if (lowercaseQuery.contains('visa') ||
        lowercaseQuery.contains('requirement')) {
      return 'requirements';
    } else if (lowercaseQuery.contains('taxi') ||
        lowercaseQuery.contains('transport')) {
      return 'transport';
    }
    return 'general';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.red
                      ? Icons.error
                      : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  T _getFieldValue<T>(DocumentSnapshot doc, String field, T defaultValue) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey(field)) {
        return data[field] ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  String _formatTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }

  void _showDestinationGuide() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(top: 15, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.place, color: Colors.blue, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      "Sri Lankan Destinations",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _sriLankanDestinations.length,
                  itemBuilder: (context, index) {
                    String key = _sriLankanDestinations.keys.elementAt(index);
                    Map<String, dynamic> destination =
                        _sriLankanDestinations[key]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      destination['name'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    Text(
                                      destination['province'],
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _showTaxiOptions(destination['name']);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.local_taxi,
                                          color: Colors.green, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Get Taxi",
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "🏖️ ${(destination['highlights'] as List).take(2).join(', ')}",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "📅 Best Time: ${destination['bestTime']}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _inputController.text =
                                  "Tell me about ${destination['name']}";
                              _sendQueryToDatabase(_inputController.text);
                            },
                            child: const Text(
                              "Tap for detailed info →",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Color(0xFF1976D2)),
              SizedBox(width: 8),
              Text("Sri Lanka Travel Guide"),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "🇱🇰 Complete Sri Lanka Assistant:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text("🏖️ Top Destinations:"),
                Text("• Trincomalee - Beautiful beaches & temples"),
                Text("• Galle - Historic fort & whale watching"),
                Text("• Jaffna - Rich Tamil culture & heritage"),
                Text("• Matale - Spice gardens & nature"),
                Text("• Kandy - Cultural capital & temples"),
                Text("• Ella - Hill country & tea plantations"),
                SizedBox(height: 12),
                Text(
                  "🚖 Taxi Integration:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("• Ask: 'taxi to [destination]'"),
                Text("• Use destination guide button"),
                Text("• PickMe & Uber support"),
                Text("• Instant app launching"),
                SizedBox(height: 12),
                Text(
                  "💡 Smart Features:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("• AI responds instantly"),
                Text("• Destination-specific info"),
                Text("• Weather & visa guidance"),
                Text("• Hotel recommendations"),
                Text("• Cultural insights"),
                SizedBox(height: 12),
                Text(
                  "🕒 Human Support: 9 AM - 8 PM (LK Time)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Got it!"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDestinationGuide();
              },
              child: const Text("View Destinations"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sri Lanka Travel Support",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (currentUser != null)
                    Text(
                      currentUser!.email ?? 'User',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.place, color: Colors.white),
            onPressed: _showDestinationGuide,
            tooltip: "Destinations",
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHelpDialog,
            tooltip: "Help",
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: Column(
          children: [
            if (currentUser == null) _buildLoginPrompt(),
            _buildQuickActions(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildChatList(),
              ),
            ),
            if (_errorMessage != null) _buildErrorBanner(),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Please log in to access personalized travel support and taxi booking",
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 65,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(action['icon'], size: 16, color: action['color']),
                label: Text(
                  action['text'],
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                onPressed: () {
                  if (action['text'].contains('taxi') ||
                      action['text'].contains('transport')) {
                    _showTaxiOptions("your destination");
                  } else {
                    _inputController.text = action['text'];
                    _inputFocusNode.requestFocus();
                  }
                },
                backgroundColor: action['color'].withOpacity(0.1),
                side: BorderSide(color: action['color'].withOpacity(0.3)),
                elevation: 2,
                pressElevation: 4,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.white.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              "Please log in to view your travel conversations",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showDestinationGuide,
              icon: const Icon(Icons.place),
              label: const Text("Explore Destinations"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('travel_queries')
          .where('userId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text("Error loading messages: ${snapshot.error}"),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text("Loading your travel conversations...",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.white.withOpacity(0.7)),
                const SizedBox(height: 16),
                Text(
                  "Welcome to Sri Lanka Travel Support!\nStart by asking about destinations, transport, or hotels.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showDestinationGuide,
                  icon: const Icon(Icons.explore),
                  label: const Text("Explore Sri Lanka"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ],
            ),
          );
        }

        var messages = snapshot.data!.docs;
        messages.sort((a, b) {
          Timestamp? aTime = a.data() != null
              ? (a.data() as Map<String, dynamic>)['timestamp']
              : null;
          Timestamp? bTime = b.data() != null
              ? (b.data() as Map<String, dynamic>)['timestamp']
              : null;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return aTime.compareTo(bTime);
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index];

            String userQuery = _getFieldValue(message, 'query', '');
            String adminReply = _getFieldValue(message, 'reply', '');
            Timestamp? timestamp =
                _getFieldValue<Timestamp?>(message, 'timestamp', null);
            String status = _getFieldValue(message, 'status', 'pending');
            bool hasAutoReply = _getFieldValue(message, 'hasAutoReply', false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChatBubble(
                  userQuery,
                  isUser: true,
                  timestamp: timestamp,
                  status: status,
                ),
                const SizedBox(height: 5),
                if (adminReply.isNotEmpty)
                  _buildChatBubble(
                    adminReply,
                    isUser: false,
                    timestamp: timestamp,
                    isAutoReply: hasAutoReply,
                  )
                else if (status == 'pending' && hasAutoReply)
                  _buildTypingIndicator(isAI: true)
                else if (status == 'pending')
                  _buildTypingIndicator(isAI: false),

                // Add taxi button for location-related messages
                if (adminReply.isNotEmpty && _containsLocation(adminReply))
                  _buildTaxiQuickAction(_extractLocationFromReply(adminReply)),

                const SizedBox(height: 15),
              ],
            );
          },
        );
      },
    );
  }

  bool _containsLocation(String message) {
    for (String location in _sriLankanDestinations.keys) {
      String locationName = location.replaceAll('_', ' ');
      String destinationName =
          _sriLankanDestinations[location]!['name'].toLowerCase();

      if (message.toLowerCase().contains(locationName) ||
          message.toLowerCase().contains(destinationName)) {
        return true;
      }
    }
    return false;
  }

  String _extractLocationFromReply(String message) {
    for (String location in _sriLankanDestinations.keys) {
      String locationName = location.replaceAll('_', ' ');
      String destinationName =
          _sriLankanDestinations[location]!['name'].toLowerCase();

      if (message.toLowerCase().contains(locationName) ||
          message.toLowerCase().contains(destinationName)) {
        return _sriLankanDestinations[location]!['name'];
      }
    }
    return "destination";
  }

  Widget _buildTaxiQuickAction(String destination) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 5),
        child: ElevatedButton.icon(
          onPressed: () => _showTaxiOptions(destination),
          icon: const Icon(Icons.local_taxi, size: 16),
          label: Text("Get Taxi to $destination",
              style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade100,
            foregroundColor: Colors.green.shade700,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    String text, {
    required bool isUser,
    Timestamp? timestamp,
    String? status,
    bool isAutoReply = false,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFFFF7043), Color(0xFFFF5722)])
              : const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft:
                isUser ? const Radius.circular(20) : const Radius.circular(5),
            bottomRight:
                isUser ? const Radius.circular(5) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && isAutoReply)
              Container(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy,
                        size: 14, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Text(
                      "🇱🇰 Sri Lanka AI Assistant",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                  if (isUser && status != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      status == 'pending'
                          ? Icons.schedule
                          : status == 'answered'
                              ? Icons.done_all
                              : Icons.done,
                      size: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator({bool isAI = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 500 + (index * 100)),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isAI ? "🇱🇰 AI is typing..." : "Support team is typing...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isTyping)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "You are typing...",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          "Ask about destinations, hotels, transport, weather...",
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.chat, color: Colors.grey.shade600),
                    ),
                    onSubmitted: (_) =>
                        _sendQueryToDatabase(_inputController.text),
                    enabled: !_isLoading && currentUser != null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: currentUser != null
                      ? const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF1565C0)])
                      : LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade500]),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading || currentUser == null
                      ? null
                      : () => _sendQueryToDatabase(_inputController.text),
                ),
              ),
            ],
          ),
          if (currentUser == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Please log in to send messages and book taxis",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
