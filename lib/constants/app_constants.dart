class AppConstants {
  static const String appName = 'Bharat Problem Solver AI';
  static const String tagline = 'One Photo. One Report. One Solution.';

  // Change this to your computer's IP if testing on real device
  // For Android emulator use: http://10.0.2.2:8000/api/v1
  // For real device use: http://YOUR_PC_IP:8000/api/v1
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिन्दी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'ml': 'മലയാളം',
    'kn': 'ಕನ್ನಡ',
  };

  static const Map<String, String> issueTypeLabels = {
    'pothole': 'Pothole',
    'garbage': 'Garbage',
    'water_leak': 'Water Leakage',
    'broken_light': 'Broken Street Light',
    'road_damage': 'Road Damage',
    'drainage': 'Drainage Blockage',
    'flooding': 'Flooding',
    'property_damage': 'Property Damage',
  };

  static const Map<String, String> issueTypeEmojis = {
    'pothole': '🕳️',
    'garbage': '🗑️',
    'water_leak': '💧',
    'broken_light': '💡',
    'road_damage': '🛣️',
    'drainage': '🚧',
    'flooding': '🌊',
    'property_damage': '🏚️',
  };

  static const Map<String, String> severityColors = {
    'high': 'CC2222',
    'medium': 'E8A020',
    'low': '138808',
  };
}