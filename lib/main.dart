import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'eve.holt@reqres.in';
    _passwordController.text = 'cityslicka';
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://reqres.in/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'reqres-free-v1',
        },
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WeatherScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Login failed: Invalid credentials';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: 20,
              child: Lottie.asset(
                'assets/animations/sunny.json',
                width: 120,
                height: 120,
                repeat: true,
                animate: true,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'WeatherSync Pro',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your Ultimate Weather Companion',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 400,
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BlurField(
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'Email (e.g., eve.holt@reqres.in)',
                                  prefixIcon: Icon(Icons.mail, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white10,
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 24),
                            BlurField(
                              child: TextField(
                                controller: _passwordController,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'Password (e.g., cityslicka)',
                                  prefixIcon: Icon(Icons.lock, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white10,
                                ),
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_errorMessage.isNotEmpty)
                              Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            _isLoading
                                ? Lottie.asset('assets/animations/loading.json', width: 100, height: 100)
                                : SkyButton(
                                    onPressed: _login,
                                    child: const Text('Login'),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _weatherData;
  String _errorMessage = '';
  bool _isLoading = true;
  final _cityController = TextEditingController();
  String _currentCity = 'London'; // Default city
  late Timer _weatherTimer;

  // Expanded city to lat/lon mapping with Indian cities
  Map<String, Map<String, double>> _cityCoordinates = {
    'London': {'latitude': 51.51, 'longitude': -0.13},
    'New York': {'latitude': 40.71, 'longitude': -74.01},
    'Tokyo': {'latitude': 35.68, 'longitude': 139.76},
    'Paris': {'latitude': 48.85, 'longitude': 2.35},
    'Sydney': {'latitude': -33.86, 'longitude': 151.21},
    'Mumbai': {'latitude': 19.08, 'longitude': 72.88},
    'Delhi': {'latitude': 28.70, 'longitude': 77.10},
    'Bangalore': {'latitude': 12.97, 'longitude': 77.59},
    'Chennai': {'latitude': 13.08, 'longitude': 80.27},
    'Kolkata': {'latitude': 22.57, 'longitude': 88.36},
  };

  @override
  void initState() {
    super.initState();
    _fetchWeather(_currentCity);
    _weatherTimer = Timer.periodic(const Duration(minutes: 15), (timer) => _fetchWeather(_currentCity));
  }

  @override
  void dispose() {
    _weatherTimer.cancel();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final normalizedCity = city.toLowerCase();
    if (!_cityCoordinates.keys.any((c) => c.toLowerCase() == normalizedCity)) {
      setState(() {
        _errorMessage = 'City not supported. Try: London, New York, Tokyo, Paris, Sydney, Mumbai, Delhi, Bangalore, Chennai, Kolkata';
        _isLoading = false;
      });
      return;
    }

    final cityMatch = _cityCoordinates.keys.firstWhere((c) => c.toLowerCase() == normalizedCity);
    final coords = _cityCoordinates[cityMatch]!;
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${coords['latitude']}&longitude=${coords['longitude']}&current_weather=true&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_sum,precipitation_probability_max&timezone=auto',
      );
      print('API Request URL: $url'); // Log the full URL
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Full API Response: $data'); // Log full response
        print('Weather code for $city: ${data['current_weather']['weathercode']}'); // Corrected to weathercode
        setState(() {
          _weatherData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load weather data: Status ${response.statusCode} - ${response.body}';
          _isLoading = false;
          print('API Error: Status ${response.statusCode}, Body: ${response.body}');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching weather: $e';
        _isLoading = false;
        print('API Exception: $e');
      });
    }
  }

  void _searchCity() {
    final city = _cityController.text.trim();
    if (city.isNotEmpty) {
      setState(() {
        _currentCity = city;
      });
      _fetchWeather(city);
    }
  }

  String _getWeatherAnimation(int? weatherCode) {
    if (weatherCode == null) {
      print('Warning: weatherCode is null, defaulting to wind.json');
      return 'assets/animations/wind.json';
    }
    switch (weatherCode) {
      case 0:
        return 'assets/animations/sunny.json';
      case 1:
      case 2:
      case 3:
        return 'assets/animations/cloudy.json';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return 'assets/animations/rainy.json';
      case 80:
      case 81:
      case 82:
        return 'assets/animations/rainy.json';
      default:
        print('Unknown weatherCode $weatherCode, defaulting to wind.json');
        return 'assets/animations/wind.json';
    }
  }

  String _getLocationDate() {
    if (_weatherData == null || _weatherData!['daily'] == null || _weatherData!['daily']['time'].isEmpty) {
      return DateTime.now().toLocal().toString().split(' ')[0]; // Fallback to current date
    }
    return _weatherData!['daily']['time'][0]; // Use API's daily date
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1), // Dark blue
              Color(0xFF000000), // Black
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            CustomPaint(
              painter: ParticlePainter(),
              child: Container(),
            ),
            _isLoading
                ? Center(child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150))
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
                            const SizedBox(height: 20),
                            SkyButton(
                              onPressed: () => _fetchWeather(_currentCity),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _weatherData != null
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: BlurField(
                                        child: TextField(
                                          controller: _cityController,
                                          decoration: const InputDecoration(
                                            hintText: 'Enter city (e.g., London)',
                                            prefixIcon: const Image(
                                              image: AssetImage('assets/images/search.png'),
                                              width: 6,
                                              height: 6,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                              borderSide: BorderSide(color: Colors.white24),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white24,
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          onSubmitted: (_) => _searchCity(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SkyButton(
                                      onPressed: _searchCity,
                                      child: const Text('Search'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$_currentCity',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          _getLocationDate(),
                                          style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Lottie.asset(
                                      _getWeatherAnimation(_weatherData!['current_weather']['weathercode'] as int?),
                                      width: 150,
                                      height: 150,
                                      animate: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Temperature',
                                              value: '${_weatherData!['current_weather']['temperature']}°C',
                                              color: Colors.blue[300]!,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Humidity',
                                              value: '${_weatherData!['hourly']['relative_humidity_2m'][0]}%',
                                              color: Colors.teal[300]!,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Wind Speed',
                                              value: '${_weatherData!['current_weather']['windspeed']} km/h',
                                              color: Colors.orange[300]!,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Max Temp',
                                              value: '${_weatherData!['daily']['temperature_2m_max'][0]}°C',
                                              color: Colors.red[300]!,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Min Temp',
                                              value: '${_weatherData!['daily']['temperature_2m_min'][0]}°C',
                                              color: Colors.blueGrey[300]!,
                                            ),
                                          ),
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Sunrise',
                                              value: _weatherData!['daily']['sunrise'][0],
                                              color: Colors.yellow[300]!,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Sunset',
                                              value: _weatherData!['daily']['sunset'][0],
                                              color: Colors.deepPurple[300]!,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Precipitation',
                                              value: '${_weatherData!['daily']['precipitation_sum'][0]} mm',
                                              color: Colors.cyan[300]!,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: WeatherCard(
                                              title: 'Precip Prob',
                                              value: '${_weatherData!['daily']['precipitation_probability_max'][0]}%',
                                              color: Colors.indigo[300]!,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class WeatherCard extends StatefulWidget {
  final String title;
  final String value;
  final Color color;

  const WeatherCard({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  _WeatherCardState createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        height: 140,
        margin: const EdgeInsets.all(8.0),
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isHovered ? 0.4 : 0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        child: GlassCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text(
              widget.title,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            trailing: Text(
              widget.value,
              style: TextStyle(color: widget.color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius!),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class BlurField extends StatelessWidget {
  final Widget child;

  const BlurField({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SkyButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const SkyButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  _SkyButtonState createState() => _SkyButtonState();
}

class _SkyButtonState extends State<SkyButton> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.cyan[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }
}

class ParticlePainter extends CustomPainter {
  final DateTime _now = DateTime.now();
  final List<Offset> _particles = List.generate(
    20,
    (index) => Offset(
      math.Random().nextDouble() * 400,
      math.Random().nextDouble() * 800,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (var particle in _particles) {
      final newX = particle.dx + math.sin(_now.millisecond / 500.0) * 2;
      final newY = particle.dy + math.cos(_now.millisecond / 500.0) * 2;
      canvas.drawCircle(Offset(newX, newY), 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}