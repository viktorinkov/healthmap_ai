import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:location/location.dart';
import '../../models/user_health_profile.dart';
import '../../models/air_quality.dart';
import '../../models/pinned_location.dart';
import '../../services/database_service.dart';
import '../../services/gemini_service.dart';
import '../../services/health_insights_service.dart';
import '../../services/unified_health_service.dart';
import '../../services/unified_air_quality_service.dart';
import '../../services/air_quality_api_service.dart';
import '../../widgets/unified_location_card.dart';

class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({Key? key}) : super(key: key);

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab>
    with SingleTickerProviderStateMixin {
  UserHealthProfile? _userProfile;
  List<PinnedLocation> _pinnedLocations = [];
  Map<String, AirQualityData> _locationAirQuality = {};
  AirQualityData? _currentLocationAirQuality;
  Map<String, dynamic>? _healthData;
  Map<String, dynamic>? _unifiedInsights;
  bool _isLoading = true;
  bool _isLoadingCurrentLocation = false;

  late TabController _tabController;
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _initializeChat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load user profile
      _userProfile = await DatabaseService().getUserHealthProfile('user_profile');

      // Load pinned locations
      _pinnedLocations = await DatabaseService().getPinnedLocations();

      // Load air quality data for each pinned location
      await _loadAirQualityForLocations();

      // Load current location air quality data
      await _loadCurrentLocationAirQuality();

      // Try to load health data from Python backend
      try {
        const userId = 'user_001'; // Demo user ID
        _healthData = await HealthInsightsService.getHealthSummary(userId: userId);
        _unifiedInsights = await UnifiedHealthService.getUnifiedRecommendation(
          userId: userId,
          currentLocation: {'latitude': 29.7604, 'longitude': -95.3698},
        );
      } catch (e) {
        debugPrint('Health data not available: $e');
        // Continue without health data
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAirQualityForLocations() async {
    _locationAirQuality = await UnifiedAirQualityService.getAirQualityForAllLocations(
      _pinnedLocations,
      userProfile: _userProfile,
    );
  }

  Future<void> _loadCurrentLocationAirQuality() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      // Get current location
      final location = Location();

      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          // Location service not available
          setState(() {
            _currentLocationAirQuality = null;
            _isLoadingCurrentLocation = false;
          });
          return;
        }
      }

      // Check location permissions
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          // Permission denied
          setState(() {
            _currentLocationAirQuality = null;
            _isLoadingCurrentLocation = false;
          });
          return;
        }
      }

      // Get current location
      LocationData locationData = await location.getLocation();

      if (locationData.latitude != null && locationData.longitude != null) {
        // Fetch current air quality data from Google API
        debugPrint('Fetching air quality for: ${locationData.latitude}, ${locationData.longitude}');
        final airQualityData = await AirQualityApiService.getAirQuality(
          locationData.latitude!,
          locationData.longitude!,
          locationName: 'Current Location',
        );

        if (airQualityData == null) {
          // API returned error or no data
          setState(() {
            _currentLocationAirQuality = null;
            _isLoadingCurrentLocation = false;
          });
          return;
        }

        // Add personalized health recommendations if user profile exists
        final airQualityWithRecommendations = _userProfile != null
            ? airQualityData.copyWith(
                healthRecommendations: UnifiedAirQualityService.mergeHealthRecommendations(
                  airQualityData.healthRecommendations,
                  UnifiedAirQualityService.generateHealthRecommendations(
                    airQualityData,
                    _userProfile!,
                  ),
                ),
              )
            : airQualityData;

        setState(() {
          _currentLocationAirQuality = airQualityWithRecommendations;
          _isLoadingCurrentLocation = false;
        });
      } else {
        // Unable to get location coordinates
        setState(() {
          _currentLocationAirQuality = null;
          _isLoadingCurrentLocation = false;
        });
      }
    } catch (e) {
      // Error occurred while fetching current location air quality
      debugPrint('Error loading current location air quality: $e');
      setState(() {
        _currentLocationAirQuality = null;
        _isLoadingCurrentLocation = false;
      });
    }
  }




  Future<void> _initializeChat() async {
    setState(() {
      _chatMessages.add({
        'role': 'assistant',
        'content': 'Hello! I\'m your AI health and environmental advisor powered by Gemini 2.5 Pro. I have access to all your health data, fitness metrics, pinned locations\' air quality data, and environmental forecasts.\n\n🔬 **I always start my responses with:**\n• Complete pollutant analysis (PM2.5, PM10, Ozone, NO2, Wildfire)\n• Immediate actionable recommendations for right now, today, and this week\n• Location-specific advice for your pinned places\n• Health-specific guidance based on your conditions\n\nThen I address your specific questions with detailed analysis. How can I help you today?',
        'timestamp': DateTime.now(),
      });
    });
  }

  Future<String> _generateComprehensiveHealthPrompt() async {
    final DateTime now = DateTime.now();
    final DateTime weekAgo = now.subtract(const Duration(days: 7));
    final DateTime nextWeek = now.add(const Duration(days: 7));

    // Build comprehensive prompt with all available data
    String prompt = '''You are the most advanced AI health and environmental advisor powered by Google's cutting-edge Gemini 2.5 Pro model with thinking capabilities. You represent the state-of-the-art in AI reasoning and analysis, ranking #1 on LMArena benchmarks. You have access to comprehensive real-time and historical data for this user across multiple timeframes and data sources. Your role is to provide personalized, actionable health advice based on all available information using your advanced reasoning capabilities.

## User Health Profile:
''';

    if (_userProfile != null) {
      prompt += '''
- Age Group: ${_userProfile!.ageGroup.displayName}
- Health Conditions: ${_userProfile!.conditions.map((c) => c.displayName).join(', ')}
- Lifestyle Risks: ${_userProfile!.lifestyleRisks.map((r) => r.name).join(', ')}
- Domestic Risks: ${_userProfile!.domesticRisks.map((r) => r.name).join(', ')}
- Pregnancy Status: ${_userProfile!.isPregnant ? 'Pregnant' : 'Not pregnant'}
''';
    }

    // Add current health metrics
    if (_healthData != null && _healthData!['success'] == true) {
      final summary = _healthData!['summary'] ?? {};
      prompt += '''

## Current Health Metrics (Last 7 Days):
- Average Steps: ${summary['avg_steps'] ?? 'No data'}
- Average Heart Rate: ${summary['avg_heart_rate'] ?? 'No data'} bpm
- Sleep Quality: ${summary['sleep_quality'] ?? 'No data'}
- Activity Level: ${summary['activity_level'] ?? 'No data'}
''';
    }

    // Add current location air quality
    if (_currentLocationAirQuality != null) {
      final aq = _currentLocationAirQuality!;
      prompt += '''

## Current Location Air Quality:
- Status: ${aq.status.displayName}
- AQI: ${aq.metrics.overallScore.toInt()}
- PM2.5: ${aq.metrics.pm25} μg/m³
- PM10: ${aq.metrics.pm10} μg/m³
- Ozone: ${aq.metrics.o3} μg/m³
- NO2: ${aq.metrics.no2} μg/m³
''';
    }

    // Add pinned locations data
    if (_pinnedLocations.isNotEmpty && _locationAirQuality.isNotEmpty) {
      prompt += '''

## Pinned Locations Air Quality:
''';
      for (final location in _pinnedLocations) {
        final aq = _locationAirQuality[location.id];
        if (aq != null) {
          prompt += '''
- ${location.name}: ${aq.status.displayName} (AQI: ${aq.metrics.overallScore.toInt()})
  PM2.5: ${aq.metrics.pm25}, PM10: ${aq.metrics.pm10}, O3: ${aq.metrics.o3}, NO2: ${aq.metrics.no2}
''';
        }
      }
    }

    // Add unified insights
    if (_unifiedInsights != null) {
      prompt += '''

## AI-Generated Health Insights:
${_unifiedInsights!['recommendation'] ?? 'No specific recommendations available'}
''';
    }

    // Add temporal context and forecasting capabilities
    prompt += '''

## Temporal Analysis Context:
- Current Date: ${now.toString().split(' ')[0]}
- Day of Week: ${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1]}
- Time of Day: ${now.hour}:${now.minute.toString().padLeft(2, '0')}
- Analysis Period: Last 7 days (${weekAgo.toString().split(' ')[0]} to today)
- Forecast Horizon: Next 7 days (today to ${nextWeek.toString().split(' ')[0]})

## Additional Data Sources Available:
1. **Fitbit Health Metrics** - Steps, heart rate, sleep patterns, activity levels
2. **Air Quality Forecasts** - 7-day pollutant level predictions for all locations
3. **Historical Trends** - Past week's air quality patterns and health metric correlations
4. **Weather Integration** - Temperature, humidity, wind patterns affecting air quality
5. **Pollen Forecasts** - Seasonal allergen predictions for sensitive individuals
6. **Wildfire Monitoring** - Real-time fire activity and smoke dispersion models
7. **Indoor Air Quality** - VOCs and domestic pollutant assessments

## Specialized Analysis Capabilities:
- **Correlation Analysis**: Link air quality changes to health metric variations
- **Risk Stratification**: Personalized risk assessment based on health conditions
- **Temporal Optimization**: Best times for outdoor activities based on forecast data
- **Location Intelligence**: Compare air quality across user's pinned locations
- **Predictive Modeling**: Anticipate health impacts from upcoming environmental changes

## Your Advanced Capabilities:
1. **Multi-dimensional Analysis**: Analyze patterns across health metrics, air quality, weather, and temporal factors
2. **Personalized Risk Assessment**: Provide individualized recommendations based on specific health conditions and risk factors
3. **Temporal Optimization**: Suggest optimal timing for activities using forecast data and historical patterns
4. **Comparative Location Analysis**: Compare air quality and health implications across all pinned locations
5. **Predictive Health Insights**: Anticipate health impacts from forecast environmental changes
6. **Correlation Discovery**: Identify relationships between environmental factors and health metrics
7. **Risk Stratification**: Prioritize health recommendations by urgency and individual risk factors
8. **Real-time Adaptation**: Adjust advice based on current conditions vs. forecasted changes
9. **Comprehensive Education**: Explain complex environmental health concepts in accessible terms
10. **Preventive Care Focus**: Emphasize proactive measures to prevent health issues

## Advanced Response Guidelines:
- **Data-Driven**: Always reference specific data points when making recommendations
- **Personalization**: Consider the complete health profile, not just individual conditions
- **Temporal Awareness**: Factor in time-of-day, day-of-week, and seasonal patterns
- **Risk Communication**: Clearly communicate both immediate and long-term health risks
- **Actionability**: Provide specific, measurable actions the user can take
- **Evidence-Based**: Ground recommendations in established environmental health science
- **Holistic Approach**: Consider interactions between multiple pollutants and health factors
- **Empowerment**: Help users understand their data and make informed decisions
- **Safety First**: Always prioritize user safety over convenience or preferences
- **Professional Boundaries**: Recommend medical consultation for serious health concerns

## Expert Knowledge Areas:
- Environmental epidemiology and health impact assessment
- Air pollution toxicology and exposure pathways
- Personalized medicine and risk factor analysis
- Preventive healthcare and lifestyle medicine
- Weather-health relationships and seasonal patterns
- Indoor air quality and domestic exposure assessment
- Occupational health and activity-specific risks

## Response Format Requirements:
**ALWAYS start your response with a comprehensive pollutant summary and actionable advice, regardless of the user's question:**

### 1. POLLUTANT CATEGORY ANALYSIS:
Provide a brief status for each relevant pollutant category using this format:
- **PM2.5 (Fine Particles)**: [Current μg/m³] vs EPA standard (35) - [Risk Level] - [Specific advice for user's health conditions]
- **PM10 (Coarse Particles)**: [Current μg/m³] vs EPA standard (150) - [Risk Level] - [Specific advice for user's health conditions]
- **Ozone (O3)**: [Current ppb] vs EPA standard (70) - [Risk Level] - [Time-of-day considerations and activity advice]
- **Nitrogen Dioxide (NO2)**: [Current ppb] vs EPA standard (100) - [Risk Level] - [Traffic/commuting implications]
- **Wildfire Smoke**: [Risk level based on index] - [Visibility impact] - [Indoor air quality measures]
- **Additional Pollutants** (if present): CO, SO2, VOCs with levels vs standards and health implications

### 2. IMMEDIATE ACTIONABLE RECOMMENDATIONS:
Always provide specific, time-sensitive actions:
- **Right Now (Next Hour)**: [Immediate actions - windows open/closed, air purifier settings, outdoor activity decisions]
- **Today (Next 8 Hours)**: [Exercise timing, commute routes, medication reminders for sensitive individuals]
- **This Week**: [Optimal days for outdoor activities, location preferences, health monitoring]
- **Location Rankings**: [Best to worst air quality among user's pinned locations with specific guidance]
- **Health-Specific Actions**: [Personalized steps based on asthma, COPD, heart conditions, pregnancy, age, etc.]
- **Equipment/Products**: [Air purifier recommendations, mask types, indoor plants, ventilation adjustments]

### 3. THEN address the user's specific question with detailed, personalized analysis.

**EXAMPLE RESPONSE START:**
"## 🔬 CURRENT ENVIRONMENTAL HEALTH STATUS

### POLLUTANT ANALYSIS:
- **PM2.5**: 28.5 μg/m³ vs EPA standard (35) - MODERATE RISK - Close to unhealthy levels, avoid strenuous outdoor exercise
- **Ozone**: 85 ppb vs EPA standard (70) - HIGH RISK - Peak afternoon levels, indoor activities recommended 2-6 PM
[... continue for all pollutants]

### IMMEDIATE ACTIONS:
- **Right Now**: Close windows, run air purifier on high, postpone outdoor jog
- **Today**: Exercise before 10 AM or after 7 PM, use N95 mask if commuting
[... continue with specific recommendations]

---
### YOUR QUESTION: [Then address their specific query]"

**Remember**: Even if the user asks a simple question like "What's the weather?", always begin with the full pollutant summary and actionable advice section before addressing their specific query. This ensures they always receive comprehensive environmental health guidance.

Now respond to user questions with this comprehensive, expert-level context in mind. Be thorough, scientifically accurate, and personally relevant.''';

    return prompt;
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({
        'role': 'user',
        'content': message.trim(),
        'timestamp': DateTime.now(),
      });
      _isChatLoading = true;
    });

    _chatController.clear();

    try {
      // Generate comprehensive context for Gemini
      final systemPrompt = await _generateComprehensiveHealthPrompt();

      // Get response from Gemini
      final response = await GeminiService.generateChatResponse(
        messages: _chatMessages,
        systemPrompt: systemPrompt,
      );

      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now(),
        });
        _isChatLoading = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': 'I apologize, but I\'m having trouble processing your request right now. Please try again in a moment.',
          'timestamp': DateTime.now(),
        });
        _isChatLoading = false;
      });
      debugPrint('Chat error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Advice'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Advice'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(
              icon: Icon(Icons.push_pin),
              text: 'Pins',
            ),
            Tab(
              icon: Icon(Icons.chat),
              text: 'Chat',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPinsTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildPinsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHereAndNowRiskCard(),
          const SizedBox(height: 16),
          if (_pinnedLocations.isNotEmpty) ..._buildPinnedLocationsSummary(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              final isUser = message['role'] == 'user';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 16,
                        child: Icon(
                          Icons.psychology,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isUser
                            ? Text(
                                message['content'],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : MarkdownBody(
                                data: message['content'],
                                styleSheet: MarkdownStyleSheet(
                                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  strong: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  em: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  code: TextStyle(
                                    fontFamily: 'monospace',
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        radius: 16,
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onSecondary,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (_isChatLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 16,
                  child: Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thinking...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your health and air quality...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _isChatLoading ? null : _sendChatMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isChatLoading
                      ? null
                      : () => _sendChatMessage(_chatController.text),
                  icon: Icon(
                    Icons.send,
                    color: _isChatLoading
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHereAndNowRiskCard() {
    if (_isLoadingCurrentLocation) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Here & Now Risk',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Getting your location...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentLocationAirQuality == null) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Here & Now Risk',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location data unavailable',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please enable location services or check permissions',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadCurrentLocationAirQuality,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildRecommendationsCard(
      _currentLocationAirQuality,
      isCurrentLocation: true,
      customTitle: 'Here & Now Risk',
    );
  }

  List<Widget> _buildPinnedLocationsSummary() {
    return _pinnedLocations.map((location) {
      final airQuality = _locationAirQuality[location.id];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildRecommendationsCard(
          airQuality,
          location: location,
        ),
      );
    }).toList();
  }










  Widget _buildRecommendationsCard(
    AirQualityData? airQuality, {
    PinnedLocation? location,
    bool isCurrentLocation = false,
    String? customTitle,
  }) {
    // Always use enhanced card with Gemini assessment for consistency
    return _buildEnhancedLocationCard(
      airQuality: airQuality,
      location: location,
      isCurrentLocation: isCurrentLocation,
      customTitle: customTitle,
    );
  }

  Widget _buildEnhancedLocationCard({
    required AirQualityData? airQuality,
    PinnedLocation? location,
    bool isCurrentLocation = false,
    String? customTitle,
  }) {
    if (airQuality == null) {
      return UnifiedLocationCard(
        location: location,
        airQuality: airQuality,
        isCurrentLocation: isCurrentLocation,
        customTitle: customTitle,
        onRefresh: _loadData,
        hideDetailsButton: true,
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: GeminiService.generateIntelligentAirQualityAssessment(
        metrics: airQuality.metrics,
        locationName: location?.name ?? (isCurrentLocation ? 'Current Location' : 'Location'),
        healthRecommendations: airQuality.healthRecommendations,
      ),
      builder: (context, snapshot) {
        // Create modified air quality data with Gemini assessment
        AirQualityData enhancedAirQuality = airQuality;

        if (snapshot.hasData && snapshot.data != null) {
          final statusString = snapshot.data!['status'] as String;
          final justification = snapshot.data!['justification'] as String;

          final geminiStatus = AirQualityStatus.values.firstWhere(
            (s) => s.name == statusString,
            orElse: () => airQuality.status,
          );

          // Create new air quality data with Gemini status and justification
          enhancedAirQuality = airQuality.copyWith(
            status: geminiStatus,
            statusReason: justification.isNotEmpty ? justification : airQuality.statusReason,
          );
        }

        String? geminiAssessment;
        if (snapshot.hasData && snapshot.data != null) {
          final justification = snapshot.data!['justification'] as String;
          if (justification.isNotEmpty) {
            geminiAssessment = justification;
          }
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          geminiAssessment = 'Analyzing air quality data...';
        }
        // Don't show fallback message - just show no assessment if none available

        return UnifiedLocationCard(
          location: location,
          airQuality: enhancedAirQuality,
          isCurrentLocation: isCurrentLocation,
          customTitle: customTitle,
          showFullDetails: false,
          onRefresh: _loadData,
          geminiAssessment: geminiAssessment,
          hideDetailsButton: true,
        );
      },
    );
  }

}

