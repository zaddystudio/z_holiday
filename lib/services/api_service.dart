import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/holiday_model.dart';

class ApiService {
  static const String _apiKey = 'PE8BfuZx9yjqoiRObH6N8iZj4JHTk5Vz';
  static const String _baseUrl = 'https://calendarific.com/api/v2';

  // --- 1. Fetch Official Holidays (WITH LOCAL CACHING) ---
  Future<List<HolidayModel>> fetchOfficialHolidays(
    String countryCode,
    String year,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'official_holidays_${countryCode}_$year';

    // CHECK CACHE FIRST: Do we already have this data saved?
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      print("Loading $year holidays from Local Cache! (0 API Calls)");
      final Map<String, dynamic> data = json.decode(cachedData);
      final List<dynamic> holidaysJson = data['response']['holidays'];
      return holidaysJson
          .map((json) => HolidayModel.fromCalendarific(json))
          .toList();
    }

    // IF NO CACHE: Fetch from the internet
    print("Fetching $year holidays from Calendarific API...");
    final url = Uri.parse(
      '$_baseUrl/holidays?api_key=$_apiKey&country=$countryCode&year=$year',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // SAVE TO CACHE FOR NEXT TIME
        await prefs.setString(cacheKey, response.body);

        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> holidaysJson = data['response']['holidays'];
        return holidaysJson
            .map((json) => HolidayModel.fromCalendarific(json))
            .toList();
      } else {
        throw Exception('Failed to load holidays.');
      }
    } catch (e) {
      throw Exception('Error fetching holidays: $e');
    }
  }

  // --- 2. Fetch Nigerian Cultural Holidays ---
  Future<List<HolidayModel>> fetchLocalNigerianFestivals() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/nigeria_cultural.json',
      );
      final List<dynamic> data = json.decode(response);
      return data.map((json) => HolidayModel.fromLocalJson(json)).toList();
    } catch (e) {
      throw Exception('Error loading local festivals: $e');
    }
  }
}
