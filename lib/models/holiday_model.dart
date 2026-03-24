class HolidayModel {
  final String title;
  final String description;
  final DateTime? exactDate; 
  final String? dateRule;    
  final String type;         
  final bool isPublicHoliday;
  final String? imagePath; // Added image path for local assets

  HolidayModel({
    required this.title,
    required this.description,
    this.exactDate,
    this.dateRule,
    required this.type,
    this.isPublicHoliday = false,
    this.imagePath, 
  });

  factory HolidayModel.fromCalendarific(Map<String, dynamic> json) {
    return HolidayModel(
      title: json['name'] ?? 'Unknown Holiday',
      description: json['description'] ?? '',
      exactDate: DateTime.tryParse(json['date']['iso'] ?? ''),
      type: (json['type'] as List).isNotEmpty ? json['type'][0] : 'General',
      isPublicHoliday: (json['type'] as List).contains('National holiday'),
      // Calendarific doesn't provide images, so this remains null
    );
  }

  factory HolidayModel.fromLocalJson(Map<String, dynamic> json) {
    return HolidayModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateRule: json['date_rule'],
      type: json['category'] ?? 'Cultural',
      isPublicHoliday: json['is_public_holiday'] ?? false,
      imagePath: json['image_path'], // Pulls the image path from our JSON
    );
  }
}

