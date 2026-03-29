class AnalyticsEvent {
  final String type;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.type,
    this.properties = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  final List<AnalyticsEvent> _events = [];
  static const int _maxEvents = 1000;

  void track(String type, [Map<String, dynamic>? properties]) {
    _events.add(AnalyticsEvent(type: type, properties: properties ?? {}));
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
  }

  void trackScreenView(String screen) => track('screen_view', {'screen': screen});
  void trackRecommendation(String category) => track('recommendation_request', {'category': category});
  void trackCardAdded(String cardType) => track('card_added', {'card_type': cardType});
  void trackCardDeleted(String cardType) => track('card_deleted', {'card_type': cardType});
  void trackError(String error) => track('error', {'message': error});

  List<AnalyticsEvent> get events => List.unmodifiable(_events);
  int get totalEvents => _events.length;

  void clearEvents() => _events.clear();
}
