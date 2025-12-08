// lib/screens/home_content.dart
import 'dart:convert';
import 'package:demo/screens/diagnose_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _locationGranted = false;
  bool _loading = false;
  String? _error;
  WeatherData? _weather;
  String _currentCrop = 'Wheat (Field A)'; 

  // <-- REPLACE with your OpenWeatherMap API key (keep secure for production) -->
  static const String _apiKey = 'a762c33c495fc7b9c9681498314ba616';

  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWeatherByLocation();
  }

  // --- Weather Fetching Methods ---

  Future<void> _fetchWeatherByLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.whileInUse && perm != LocationPermission.always) {
        setState(() {
          _error = 'Location permission not granted.';
          _locationGranted = false;
        });
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() {
          _error = 'Location services are disabled.';
          _locationGranted = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .timeout(const Duration(seconds: 15));

      await _fetchWeatherByCoords(pos.latitude, pos.longitude);
      setState(() {
        _locationGranted = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeatherByCoords(double lat, double lon) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/weather',
        {'lat': lat.toString(), 'lon': lon.toString(), 'appid': _apiKey, 'units': 'metric'},
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final map = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _weather = WeatherData.fromJson(map);
        });
      } else {
        final map = json.decode(resp.body);
        setState(() {
          _error = map['message'] ?? 'Weather API error ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Weather fetch failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeatherByCity(String city) async {
    if (city.trim().isEmpty) {
      setState(() => _error = 'Please enter a city name.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'q': city,
        'appid': _apiKey,
        'units': 'metric',
      });
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final map = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _weather = WeatherData.fromJson(map);
          _locationGranted = false; // result came from manual city search
        });
      } else {
        final map = json.decode(resp.body);
        setState(() {
          _error = map['message'] ?? 'Weather API error ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Weather fetch failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  // --- Advice and Utility Methods ---

  // small dialog to enter city name
  Future<void> _citySearchDialog() async {
    _cityController.text = _weather?.cityName ?? '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search city'),
        content: TextField(
          controller: _cityController,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: 'Enter city (e.g., Mumbai)'),
          onSubmitted: (v) {
            Navigator.of(ctx).pop();
            _fetchWeatherByCity(v.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final city = _cityController.text.trim();
              Navigator.of(ctx).pop();
              _fetchWeatherByCity(city);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  // irrigation advice (unchanged heuristics)
  String _irrigationAdvice(WeatherData w) {
    final temp = w.temperature;
    final humidity = w.humidity;
    final desc = w.description.toLowerCase();
    if (desc.contains('rain')) return 'Rain expected — hold irrigation.';
    if (humidity > 80) return 'High humidity — hold irrigation & monitor disease.';
    if (temp > 30 && humidity < 40) return 'Hot & dry — irrigate soon.';
    return 'Normal — follow schedule.';
  }

  // Basic disease risk assessment logic
  String _diseaseRiskAssessment(WeatherData? w) {
    if (w == null) return '—';
    
    final temp = w.temperature;
    final humidity = w.humidity;
    final desc = w.description.toLowerCase();

    // High risk when wet + warm/hot
    if ((desc.contains('rain') || desc.contains('drizzle')) && temp > 18) return 'High';
    if (humidity > 80 && temp > 25) return 'Moderate';
    
    // Low risk when dry or cold
    if (humidity < 60 || temp < 10) return 'Low';
    
    return 'Moderate';
  }

  // Crop/Field Selection Header
  Widget _cropSelectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Field Selection (TODO)')));
        },
        child: Row(
          children: [
            Icon(Icons.location_pin, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(_currentCrop, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final cardBg = theme.cardTheme.color ?? scheme.surface;
    final cardShadow = theme.cardTheme.shadowColor ?? Colors.black12;
    final accent = scheme.primary;
    final accentContrast = scheme.onPrimary;
    final muted = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final yellowAccent = scheme.secondary;

    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          _cropSelectionHeader(context),

          // Horizontal top cards (weather + two info cards)
          SizedBox(
            height: 140, // Fixed size for horizontal list
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return _weatherInfoCard(context, cardBg, accent, yellowAccent);
                }
                if (i == 1) return _miniInfoCard(context, 'Spraying cycle', 'Moderate', Icons.grass);
                // Use disease risk assessment
                return _miniInfoCard(context, 'Disease risk', _diseaseRiskAssessment(_weather), Icons.health_and_safety);
              },
            ),
          ),

          const SizedBox(height: 20),

          // "Heal your crop" heading
          Text('Heal your crop', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          // Big Heal your crop card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: cardShadow.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(children: [
              // three step icons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stepItem(context, Icons.crop_free, 'Take a\npicture'),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                  _stepItem(context, Icons.document_scanner_outlined, 'See\ndiagnosis'),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                  _stepItem(context, Icons.local_pharmacy_outlined, 'Get\nmedicine'),
                ],
              ),
              const SizedBox(height: 18),
              // CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DiagnoseScreen(),));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accessing camera ')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: accentContrast,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Take a picture', style: theme.textTheme.labelLarge?.copyWith(color: accentContrast)),
                ),
              )
            ]),
          ),

          const SizedBox(height: 20),

          // Manage your fields header
          Text('Manage your fields', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          // Manage your fields card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: cardShadow.withOpacity(0.06), blurRadius: 6)],
                ),
                child: Icon(Icons.map_outlined, color: accent, size: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Start precision farming', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Add your field to unlock tailored insights and nutrient plans', style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                ]),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add field (TODO)')));
                },
                icon: const Icon(Icons.add),
                label: const Text('Add field'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: accentContrast,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            ]),
          ),

          const SizedBox(height: 18),

          // small cards row 1
          Row(children: [
            Expanded(child: _smallRoundedCard(context, 'Fertilizer', Icons.local_florist)),
            const SizedBox(width: 12),
            Expanded(child: _smallRoundedCard(context, 'Pest', Icons.bug_report)),
          ]),

          const SizedBox(height: 18),

          // small cards row 2
          Row(children: [
            Expanded(child: _smallRoundedCard(context, 'Markets', Icons.store)),
            const SizedBox(width: 12),
            Expanded(child: _smallRoundedCard(context, 'Community', Icons.forum_outlined)),
          ]),

          const SizedBox(height: 40),

          // footer advice area (shows only when weather is available)
          if (_weather != null) ...[
            Text('Advice', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            // Irrigation Advice Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.water_drop_outlined, color: Colors.blue),
                title: Text(_irrigationAdvice(_weather!)),
                subtitle: Text('Temp ${_weather!.temperature.toStringAsFixed(1)}°C (Feels like ${_weather!.feelsLike.toStringAsFixed(0)}°C) · Humidity ${_weather!.humidity}%'),
                trailing: IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
              ),
            ),
            const SizedBox(height: 8),
            // Market Alert Card
            Card(
              color: scheme.secondaryContainer.withOpacity(0.1),
              child: ListTile(
                leading: Icon(Icons.trending_up, color: scheme.secondary),
                title: const Text('Market Price Alert: Wheat'),
                subtitle: const Text('Local Mandi price is up 5% this week. Consider selling 25% of stock.'),
                trailing: IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
              ),
            ),
          ] else if (_error != null) ...[
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
          ] else ...[
            // nothing
          ],
        ]),
      ),
    );
  }

  // Weather card builder (with responsive bottom strip)
  Widget _weatherInfoCard(BuildContext context, Color cardBg, Color accent, Color yellowAccent) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final shadow = theme.cardTheme.shadowColor ?? Colors.black12;

    final locationText = _locationGranted ? _weather?.cityName ?? 'Location enabled' : 'Location permission required';
    final tempText = _weather != null ? '${_weather!.temperature.toStringAsFixed(0)}°C' : '—';
    final condText = _weather != null ? _weather!.description : 'Clear • 24°C / 20°C';
    
    // Calculate the height of the bottom strip for the expanded widget's calculation
    // Max narrow height (icon+text, 6px space, button, 6px padding top/bottom) is roughly 60px
    const double bottomStripHeight = 58.0; 

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: yellowAccent.withOpacity(0.9), width: 1.4),
        boxShadow: [BoxShadow(color: shadow.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // TOP HEADER ROW (weather display area)
          InkWell(
            onTap: _citySearchDialog,
            child: Padding(
              // Reduced top padding and set minimal bottom padding
              padding: const EdgeInsets.fromLTRB(16, 10, 14, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Ensure column minimizes vertical space
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Today, ${_formatDate(DateTime.now())}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          condText,
                          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                          maxLines: 1, // Restrict to one line to help control height
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tempText, style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
                      const SizedBox(height: 4),
                      Icon(Icons.wb_sunny, color: yellowAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // MIDDLE - EXPANDED AREA (Loader or Empty Space)
          Expanded(
            child: Center(
              // Using AnimatedSwitcher ensures seamless appearance and disappearance
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                // The SizedBox below is key: it takes up the remaining available height
                // minus the height of the top header and bottom strip.
                child: _loading
                    ? SizedBox(
                        key: const ValueKey('loader'),
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(color: accent, strokeWidth: 2.4),
                      )
                    : const SizedBox(
                        key: ValueKey('empty'),
                        height: 26, // Keep height consistent when showing status/empty
                      ),
              ),
            ),
          ),

          // BOTTOM STRIP (fixed height, responsive layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 280;
              final btnStyle = TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );

              final statusText = Text(
                locationText,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );

              final allowButton = TextButton(
                style: btnStyle,
                onPressed: () async => await _fetchWeatherByLocation(),
                child: Text(
                  _locationGranted ? 'Enabled' : 'Allow',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              );

              // Narrow (two-line) layout
              if (isNarrow) {
                return Container(
                  decoration: BoxDecoration(
                    color: yellowAccent.withOpacity(0.12),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  ),
                  // Adjusted vertical padding to fit within 140 height
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Essential for tight fit
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: theme.colorScheme.onBackground.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Expanded(child: statusText),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(alignment: Alignment.centerRight, child: allowButton),
                    ],
                  ),
                );
              }

              // Wide (one-line) layout
              return Container(
                decoration: BoxDecoration(
                  color: yellowAccent.withOpacity(0.12),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: theme.colorScheme.onBackground.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Expanded(child: statusText),
                    const SizedBox(width: 8),
                    allowButton,
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _miniInfoCard(BuildContext context, String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final muted = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final shadow = theme.cardTheme.shadowColor ?? Colors.black12;

    return Container(
      width: 260,
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: shadow.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: theme.colorScheme.primary)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700))),
        ]),
        const Spacer(),
        // Check if subtitle indicates risk/alert, and highlight it
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: subtitle == 'High' || subtitle.contains('Alert') ? theme.colorScheme.error : muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Align(alignment: Alignment.bottomRight, child: Icon(Icons.chevron_right, color: muted?.withOpacity(0.6))),
      ]),
    );
  }

  Widget _stepItem(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 28, color: theme.colorScheme.primary)),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
      ]),
    );
  }

  Widget _smallRoundedCard(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final shadow = theme.cardTheme.shadowColor ?? Colors.black12;

    return Container(
      height: 84,
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: shadow.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: theme.colorScheme.primary)),
        const SizedBox(width: 12),
        Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
      ]),
    );
  }

  String _formatDate(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

// ---------- Weather model ----------
class WeatherData {
  final String cityName;
  final String country;
  final double temperature; // Celsius
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final String? main; // e.g., "Rain", "Clear"

  WeatherData({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    this.main,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final mainData = json['main'] ?? {};
    final wind = json['wind'] ?? {};
    final weatherList = (json['weather'] as List<dynamic>?) ?? [];
    final weather = weatherList.isNotEmpty ? weatherList[0] : {};
    return WeatherData(
      cityName: json['name'] ?? 'Unknown',
      country: (json['sys']?['country']) ?? '',
      temperature: (mainData['temp'] ?? 0).toDouble(),
      feelsLike: (mainData['feels_like'] ?? 0).toDouble(),
      humidity: (mainData['humidity'] ?? 0).toInt(),
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      description: (weather['description'] ?? '').toString(),
      icon: (weather['icon'] ?? '01d').toString(),
      main: (weather['main'] ?? '')?.toString(),
    );
  }
}