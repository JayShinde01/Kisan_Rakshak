// lib/screens/home_content.dart
import 'dart:convert';
import 'package:demo/screens/diagnose_screen.dart';
import 'package:demo/screens/Marketplace_screen.dart';
import 'package:demo/screens/community_post_page.dart';
import 'package:demo/screens/field_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

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

  // OpenWeatherMap API key
  static const String _apiKey = 'a762c33c495fc7b9c9681498314ba616';

  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWeatherByLocation();
  }

  // --- WEATHER LOGIC (Robust version) ---

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
          _error = tr('location_permission_not_granted');
          _locationGranted = false;
        });
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() {
          _error = tr('location_services_disabled');
          _locationGranted = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .timeout(const Duration(seconds: 15));

      await _fetchWeatherByCoords(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _locationGranted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${tr('failed_get_location')}: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
          _error = map['message'] ?? '${tr('weather_api_error')} ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = '${tr('weather_fetch_failed')}: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeatherByCity(String city) async {
    if (city.trim().isEmpty) {
      setState(() => _error = tr('enter_city_name'));
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
          _locationGranted = false;
        });
      } else {
        final map = json.decode(resp.body);
        setState(() {
          _error = map['message'] ?? '${tr('weather_api_error')} ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = '${tr('weather_fetch_failed')}: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _citySearchDialog() async {
    _cityController.text = _weather?.cityName ?? '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('search_city')),
        content: TextField(
          controller: _cityController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: tr('enter_city_example')),
          onSubmitted: (v) {
            Navigator.of(ctx).pop();
            _fetchWeatherByCity(v.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () {
              final city = _cityController.text.trim();
              Navigator.of(ctx).pop();
              _fetchWeatherByCity(city);
            },
            child: Text(tr('search')),
          ),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  String _irrigationAdvice(WeatherData w) {
    final temp = w.temperature;
    final humidity = w.humidity;
    final desc = w.description.toLowerCase();
    if (desc.contains('rain')) return tr('irrigation_rain_expected');
    if (humidity > 80) return tr('irrigation_high_humidity');
    if (temp > 30 && humidity < 40) return tr('irrigation_hot_dry');
    return tr('irrigation_normal');
  }

  String _diseaseRiskAssessment(WeatherData? w) {
    if (w == null) return '—';
    final temp = w.temperature;
    final humidity = w.humidity;
    final desc = w.description.toLowerCase();

    if ((desc.contains('rain') || desc.contains('drizzle')) && temp > 18) return tr('risk_high');
    if (humidity > 80 && temp > 25) return tr('risk_moderate');
    if (humidity < 60 || temp < 10) return tr('risk_low');

    return tr('risk_moderate');
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final cardBg = theme.cardTheme.color ?? scheme.surface;
    final cardShadow = theme.cardTheme.shadowColor ?? Colors.black12;
    final accent = scheme.primary;
    final accentContrast = scheme.onPrimary;
    final yellowAccent = scheme.secondary;

    return Container(
      color: bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: Center content on wide screens (Desktop/Web)
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _cropSelectionHeader(context),

                  // Horizontal Weather & Risk Cards
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          return _weatherInfoCard(context, cardBg, accent, yellowAccent);
                        }
                        if (i == 1) return _miniInfoCard(context, tr('spraying_cycle'), tr('moderate'), Icons.grass);
                        return _miniInfoCard(context, tr('disease_risk'), _diseaseRiskAssessment(_weather), Icons.health_and_safety);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Diagnose Section (Rich UI + Navigation)
                  Text(tr('heal_your_crop'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: cardShadow.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))]),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _stepItem(context, Icons.crop_free, tr('take_a_picture_short')),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                          _stepItem(context, Icons.document_scanner_outlined, tr('see_diagnosis')),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                          _stepItem(context, Icons.local_pharmacy_outlined, tr('get_medicine')),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const DiagnoseScreen()));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('accessing_camera'))));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: accentContrast, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: Text(tr('take_a_picture'), style: theme.textTheme.labelLarge?.copyWith(color: accentContrast)),
                        ),
                      )
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // Manage Fields Section (Navigation Added)
                  Text(tr('manage_your_fields'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: scheme.primaryContainer.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: cardShadow.withOpacity(0.06), blurRadius: 6)]),
                        child: Icon(Icons.map_outlined, color: accent, size: 36),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('start_precision_farming'), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(tr('add_your_field_unlock_insights'), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldMapScreen()));
                        },
                        icon: const Icon(Icons.add),
                        label: Text(tr('add_field')),
                        style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: accentContrast, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      )
                    ]),
                  ),

                  const SizedBox(height: 18),

                  // Grid Menu Buttons (Navigation Mapped)
                  Row(children: [
                    Expanded(
                      child: _smallRoundedCard(context, tr('fertilizer'), Icons.local_florist, onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplacePage()));
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _smallRoundedCard(context, tr('pest'), Icons.bug_report, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnoseScreen()));
                      }),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(
                      child: _smallRoundedCard(context, tr('markets'), Icons.store, onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplacePage()));
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _smallRoundedCard(context, tr('community'), Icons.forum_outlined, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPostPage()));
                      }),
                    ),
                  ]),

                  const SizedBox(height: 40),

                  // Advice Section (from Rich UI)
                  if (_weather != null) ...[
                    Text(tr('advice'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.water_drop_outlined, color: Colors.blue),
                        title: Text(_irrigationAdvice(_weather!)),
                        subtitle: Text('${tr('temp')} ${_weather!.temperature.toStringAsFixed(1)}°C · ${tr('humidity')} ${_weather!.humidity}%'),
                        trailing: IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: scheme.secondaryContainer.withOpacity(0.1),
                      child: ListTile(
                        leading: Icon(Icons.trending_up, color: scheme.secondary),
                        title: Text(tr('market_price_alert_wheat')),
                        subtitle: Text(tr('market_price_alert_details')),
                        trailing: IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
                      ),
                    ),
                  ] else if (_error != null) ...[
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                  ],
                ]),
              ),
            ),
          );
        }
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _cropSelectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('open_field_selection'))));
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

  Widget _weatherInfoCard(BuildContext context, Color cardBg, Color accent, Color yellowAccent) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final shadow = theme.cardTheme.shadowColor ?? Colors.black12;

    final locationText = _locationGranted ? _weather?.cityName ?? tr('location_enabled') : tr('location_permission_required');
    final tempText = _weather != null ? '${_weather!.temperature.toStringAsFixed(0)}°C' : '—';
    final condText = _weather != null ? _weather!.description : tr('clear_default_temp');

    return Container(
      width: 320,
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: yellowAccent.withOpacity(0.9), width: 1.4), boxShadow: [BoxShadow(color: shadow.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          InkWell(
            onTap: _citySearchDialog,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 14, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text('${tr('today')}, ${_formatDate(DateTime.now())}', style: theme.textTheme.bodyMedium?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(condText, style: theme.textTheme.bodyMedium?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [Text(tempText, style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)), const SizedBox(height: 4), Icon(Icons.wb_sunny, color: yellowAccent)]),
                ],
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _loading ? SizedBox(key: const ValueKey('loader'), height: 26, width: 26, child: CircularProgressIndicator(color: accent, strokeWidth: 2.4)) : const SizedBox(key: ValueKey('empty'), height: 26),
              ),
            ),
          ),

          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 280;
            final btnStyle = TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap);
            final statusText = Text(locationText, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis);
            final allowButton = TextButton(style: btnStyle, onPressed: () async => await _fetchWeatherByLocation(), child: Text(_locationGranted ? tr('enabled') : tr('allow'), style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)));

            if (isNarrow) {
              return Container(
                decoration: BoxDecoration(color: yellowAccent.withOpacity(0.12), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18))),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Row(children: [Icon(Icons.location_on_outlined, color: theme.colorScheme.onBackground.withOpacity(0.7)), const SizedBox(width: 8), Expanded(child: statusText)]), const SizedBox(height: 6), Align(alignment: Alignment.centerRight, child: allowButton)]),
              );
            }
            return Container(
              decoration: BoxDecoration(color: yellowAccent.withOpacity(0.12), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18))),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [Icon(Icons.location_on_outlined, color: theme.colorScheme.onBackground.withOpacity(0.7)), const SizedBox(width: 8), Expanded(child: statusText), const SizedBox(width: 8), allowButton]),
            );
          }),
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
        Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: theme.colorScheme.primary)), const SizedBox(width: 10), Expanded(child: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)))]),
        const Spacer(),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: subtitle == tr('risk_high') || subtitle.contains(tr('alert')) ? theme.colorScheme.error : muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Align(alignment: Alignment.bottomRight, child: Icon(Icons.chevron_right, color: muted?.withOpacity(0.6))),
      ]),
    );
  }

  Widget _stepItem(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 28, color: theme.colorScheme.primary)), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)]),
    );
  }

  Widget _smallRoundedCard(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final shadow = theme.cardTheme.shadowColor ?? Colors.black12;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 84,
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: shadow.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 4))]),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: theme.colorScheme.primary)), 
          const SizedBox(width: 12), 
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700))), 
          Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))
        ]),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = [tr('mon_jan'), tr('mon_feb'), tr('mon_mar'), tr('mon_apr'), tr('mon_may'), tr('mon_jun'), tr('mon_jul'), tr('mon_aug'), tr('mon_sep'), tr('mon_oct'), tr('mon_nov'), tr('mon_dec')];
    return '${d.day} ${months[d.month - 1]}';
  }
}

// Full Weather Model (Preserved from Rich Code)
class WeatherData {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final String? main;

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