import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/holiday_model.dart';
import '../services/api_service.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  static const Color _darkGreen = Color(0xFF006400);

  String _selectedCountryCode = 'NG';
  String _currentYear = DateTime.now().year.toString();

  final Map<String, String> _countries = {
    'NG': 'Nigeria',
    'GH': 'Ghana',
    'ZA': 'South Africa',
    'KE': 'Kenya',
    'US': 'United States',
    'GB': 'United Kingdom',
  };

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<HolidayModel>> _groupedHolidays = {};
  List<HolidayModel> _culturalFestivals = [];
  bool _isLoading = true;
  Set<String> _favorites = {};
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadFavorites();
    _fetchData();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch $url';
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = (prefs.getStringList('my_favorite_holidays') ?? []).toSet();
    });
  }

  Future<void> _toggleFavorite(String holidayId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(holidayId)) {
        _favorites.remove(holidayId);
      } else {
        _favorites.add(holidayId);
      }
      prefs.setStringList('my_favorite_holidays', _favorites.toList());
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final officialHolidays = await _apiService.fetchOfficialHolidays(
        _selectedCountryCode,
        _currentYear,
      );
      final culturalHolidays = await _apiService.fetchLocalNigerianFestivals();
      Map<DateTime, List<HolidayModel>> newGrouped = {};
      for (var holiday in officialHolidays) {
        if (holiday.exactDate != null) {
          final date = DateTime.utc(
            holiday.exactDate!.year,
            holiday.exactDate!.month,
            holiday.exactDate!.day,
          );
          if (newGrouped[date] == null) newGrouped[date] = [];
          newGrouped[date]!.add(holiday);
        }
      }
      setState(() {
        _groupedHolidays = newGrouped;
        _culturalFestivals = culturalHolidays;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<HolidayModel> _getHolidaysForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _groupedHolidays[normalizedDay] ?? [];
  }

  String _getCountdownText(DateTime? exactDate) {
    if (exactDate == null) return '';
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final holidayDate = DateTime(
      exactDate.year,
      exactDate.month,
      exactDate.day,
    );
    final difference = holidayDate.difference(today).inDays;
    if (difference < 0) return 'Past';
    if (difference == 0) return 'Today!';
    if (difference == 1) return 'Tomorrow';
    return 'In $difference days';
  }

  Color _getCountdownColor(DateTime? exactDate) {
    if (exactDate == null) return Colors.grey;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final holidayDate = DateTime(
      exactDate.year,
      exactDate.month,
      exactDate.day,
    );
    final difference = holidayDate.difference(today).inDays;
    if (difference < 0) return Colors.grey;
    if (difference == 0) return Colors.red;
    if (difference <= 7) return Colors.orange;
    return Colors.green;
  }

  void _shareHoliday(HolidayModel holiday) {
    String text = "🎉 Getting ready for ${holiday.title}!";
    if (holiday.exactDate != null) {
      final daysText = _getCountdownText(holiday.exactDate);
      text =
          "🎉 $daysText until ${holiday.title}! Checked via zHoliday App by Zaddy Digital.";
    }
    Share.share(text);
  }

  void _addToNativeCalendar(HolidayModel holiday) {
    if (holiday.exactDate == null) return;
    final Event event = Event(
      title: holiday.title,
      description: holiday.description,
      location: _countries[_selectedCountryCode] ?? 'Global',
      startDate: holiday.exactDate!,
      endDate: holiday.exactDate!.add(const Duration(days: 1)),
      allDay: true,
    );
    Add2Calendar.addEvent2Cal(event);
  }

  void _showAboutBottomSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white10, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Zaddy Digital Solutions",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "...digitally outstanding",
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "We build custom apps for different fields and industries. Bring your vision to life.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.language),
                    label: const Text(
                      "See Our Recent Apps",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () =>
                        _launchUrl("https://zaddyhost.top/creatives"),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      side: BorderSide(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      "Chat on WhatsApp",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () => _launchUrl("https://wa.me/2347060633216"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<HolidayModel> selectedHolidays = _getHolidaysForDay(
      _selectedDay ?? _focusedDay,
    );
    if (_showOnlyFavorites) {
      selectedHolidays = selectedHolidays.where((h) {
        final id = "${h.title}_${h.exactDate?.toIso8601String() ?? h.dateRule}";
        return _favorites.contains(id);
      }).toList();
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          foregroundColor: _darkGreen,
          elevation: 8,
          shape: const CircleBorder(),
          onPressed: () => _showAboutBottomSheet(context),
          child: const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Text(
              'i',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),

        // --- NEW: THE NESTED SCROLL VIEW FOR THE SLIVER HEADER ---
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                // This makes the top bar thick enough to show your image
                expandedHeight: 220.0,
                // This ensures your controls never disappear
                pinned: true,
                floating: false,
                backgroundColor: isDarkMode
                    ? Colors.grey.shade900
                    : Colors.green.shade800,

                // Your pinned controls:
                title: const Text(
                  'World Holidays',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      List<HolidayModel> allSearchableHolidays =
                          _groupedHolidays.values
                              .expand((element) => element)
                              .toList();
                      final DateTime? selectedSearchDate =
                          await showSearch<DateTime?>(
                            context: context,
                            delegate: HolidaySearchDelegate(
                              allSearchableHolidays,
                            ),
                          );
                      if (selectedSearchDate != null) {
                        setState(() {
                          _focusedDay = selectedSearchDate;
                          _selectedDay = selectedSearchDate;
                          if (selectedSearchDate.year.toString() !=
                              _currentYear) {
                            _currentYear = selectedSearchDate.year.toString();
                            _fetchData();
                          }
                        });
                      }
                    },
                  ),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (_, ThemeMode currentMode, __) {
                      return IconButton(
                        icon: Icon(
                          currentMode == ThemeMode.light
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                        onPressed: () {
                          themeNotifier.value = currentMode == ThemeMode.light
                              ? ThemeMode.dark
                              : ThemeMode.light;
                        },
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        dropdownColor: isDarkMode
                            ? Colors.grey.shade900
                            : Colors.green.shade900,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        items: _countries.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null &&
                              newValue != _selectedCountryCode) {
                            setState(() => _selectedCountryCode = newValue);
                            _fetchData();
                          }
                        },
                      ),
                    ),
                  ),
                ],

                // --- THE BEAUTIFUL IMAGE BANNER ---
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ensure you put the generated banner.jpg in assets/images/ !
                      Image.asset(
                        'assets/images/banner.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: _darkGreen,
                        ), // Fallback if image missing
                      ),
                      // A dark gradient so your text and icons pop
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // The central zHoliday logo text!
                      const Center(
                        child: Text(
                          "zHoliday",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // The TabBar stays pinned right under the app bar!
                bottom: const TabBar(
                  indicatorColor: Colors.orange,
                  indicatorWeight: 4,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(icon: Icon(Icons.public), text: "Global Dates"),
                    Tab(icon: Icon(Icons.festival), text: "Naija Culture"),
                  ],
                ),
              ),
            ];
          },

          // --- TAB VIEWS ---
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : TabBarView(
                  children: [
                    // TAB 1: CALENDAR & DATES
                    // Changed from Column to ListView so the whole page scrolls smoothly!
                    ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        TableCalendar<HolidayModel>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          calendarFormat: _calendarFormat,
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() => _calendarFormat = format);
                            }
                          },
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.twoWeeks: '2 Weeks',
                            CalendarFormat.week: 'Week',
                          },
                          eventLoader: _getHolidaysForDay,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.green.shade400,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.green.shade700,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            defaultTextStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            weekendTextStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.red.shade300
                                  : Colors.red,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            titleTextStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                            formatButtonVisible: true,
                            formatButtonDecoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            formatButtonTextStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.greenAccent
                                  : Colors.green.shade800,
                            ),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                            if (focusedDay.year.toString() != _currentYear) {
                              setState(
                                () => _currentYear = focusedDay.year.toString(),
                              );
                              _fetchData();
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "Favorites Only",
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: _showOnlyFavorites,
                                activeColor: Colors.red,
                                onChanged: (val) =>
                                    setState(() => _showOnlyFavorites = val),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Holiday List attached below the calendar
                        if (selectedHolidays.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                _showOnlyFavorites
                                    ? "No favorites on this date."
                                    : "No official holidays on this date.",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap:
                                true, // Crucial for embedding in another ListView!
                            physics:
                                const NeverScrollableScrollPhysics(), // Scroll handled by parent
                            itemCount: selectedHolidays.length,
                            itemBuilder: (context, index) {
                              final holiday = selectedHolidays[index];
                              final holidayId =
                                  "${holiday.title}_${holiday.exactDate?.toIso8601String() ?? holiday.dateRule}";
                              final isFav = _favorites.contains(holidayId);
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: Icon(
                                          Icons.flag,
                                          color: Colors.green.shade500,
                                        ),
                                        title: Text(
                                          holiday.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(holiday.description),
                                      ),
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            holiday.exactDate != null
                                                ? Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getCountdownColor(
                                                        holiday.exactDate,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _getCountdownText(
                                                        holiday.exactDate,
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    isFav
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _toggleFavorite(
                                                        holidayId,
                                                      ),
                                                ),
                                                if (holiday.exactDate != null)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit_calendar,
                                                      color: Colors.blue,
                                                    ),
                                                    onPressed: () =>
                                                        _addToNativeCalendar(
                                                          holiday,
                                                        ),
                                                  ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.share,
                                                    color: Colors.green,
                                                  ),
                                                  onPressed: () =>
                                                      _shareHoliday(holiday),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),

                    // TAB 2: NIGERIAN CULTURE
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _culturalFestivals.length,
                      itemBuilder: (context, index) {
                        final festival = _culturalFestivals[index];
                        final holidayId =
                            "${festival.title}_${festival.dateRule}";
                        final isFav = _favorites.contains(holidayId);
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (festival.imagePath != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.asset(
                                    festival.imagePath!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 150,
                                              color: isDarkMode
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade300,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            festival.title,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.green.shade300
                                                  : Colors.green.shade900,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _toggleFavorite(holidayId),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          festival.dateRule ??
                                              'Date varies annually',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      festival.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _shareHoliday(festival),
                                        icon: const Icon(Icons.share, size: 18),
                                        label: const Text("Share"),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor:
                                              Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class HolidaySearchDelegate extends SearchDelegate<DateTime?> {
  final List<HolidayModel> holidays;
  HolidaySearchDelegate(this.holidays);
  @override
  String get searchFieldLabel => 'Search holidays...';
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget? buildLeading(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    ),
  ][0];
  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();
  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();
  Widget _buildSearchResults() {
    final results = holidays
        .where((h) => h.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (results.isEmpty) return const Center(child: Text('No holidays found.'));
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final h = results[index];
        return ListTile(
          leading: const Icon(Icons.event, color: Colors.green),
          title: Text(
            h.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            h.exactDate?.toString().substring(0, 10) ?? h.dateRule ?? "",
          ),
          onTap: () => close(context, h.exactDate),
        );
      },
    );
  }
}
