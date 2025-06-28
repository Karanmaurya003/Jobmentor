import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:jobmentor/models/job.dart';
import 'package:jobmentor/screens/job_details_screen.dart';
import 'package:jobmentor/screens/profile_screen.dart';
import 'package:jobmentor/screens/resume_builder_screen.dart';
import 'package:jobmentor/screens/career_roadmap_screen.dart';
import 'package:jobmentor/screens/login_view.dart';
import 'package:jobmentor/services/job_api_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await sb.Supabase.initialize(
    url: 'https://wrehjsgdnxwxxpjbkfyc.supabase.co',       // ⬅️ Replace with your Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndyZWhqc2dkbnh3eHhwamJrZnljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMxNjc1NzUsImV4cCI6MjA1ODc0MzU3NX0.slAINzkrertzJIvcvos8-2_inKvGBnmpvcM1PN8QLhM',                         // ⬅️ Replace with your Supabase anon/public key
  );

  runApp(const JobMentorApp());
}
class JobMentorApp extends StatelessWidget {
  const JobMentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobMentor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthGate(),
    );
  }
}

/// Shows either [LoginView] or [MainPage] depending on FirebaseAuth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While waiting for the first auth event, show a splash/loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If we have a user, go to MainPage, else to LoginView
        if (snapshot.data != null) {
          return const MainPage();
        } else {
          return const LoginView();
        }
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<Color?> _backgroundAnimation;

  List<Job> filteredJobs = [];
  bool isLoading = false;
  String error = '';

  bool _useMyLocation = false;
  String? _userCity;
  bool _locLoading = false;
  String? _locError;

  @override
  void initState() {
    super.initState();
    _fetchInitialJobs();
    searchController.addListener(_onSearchChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Colors.blue.shade100,
      end: Colors.purple.shade100,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _filterJobs();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _filterJobs() async {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      await _fetchInitialJobs();
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final jobs = await JobApiService.fetchJobs(
        query,
        location: _useMyLocation ? _userCity : null,
      );
      setState(() => filteredJobs = jobs);
    } catch (e) {
      final msg = e.toString();
      error = msg.contains('status 429')
          ? 'Too many requests – please slow down and try again in a moment.'
          : 'Error fetching jobs: $e';
      setState(() {});
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchInitialJobs() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final jobs = await JobApiService.fetchJobs(
        'developer',
        location: _useMyLocation ? _userCity : null,
      );
      setState(() => filteredJobs = jobs);
    } catch (e) {
      final msg = e.toString();
      error = msg.contains('status 429')
          ? 'Too many requests – please slow down and try again in a moment.'
          : 'Error fetching jobs: $e';
      setState(() {});
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleUseMyLocation(bool value) async {
    if (value) {
      setState(() {
        _locLoading = true;
        _locError = null;
      });

      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          throw 'Location permission denied';
        }

        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        if (Platform.isWindows) {
          _userCity = await _fetchCityFromCoords(
              pos.latitude, pos.longitude);
          if (_userCity == null) throw 'Could not determine city';
        } else {
          final place = (await placemarkFromCoordinates(
            pos.latitude,
            pos.longitude,
          )).first;
          _userCity = place.locality ?? place.subAdministrativeArea;
        }
      } catch (e) {
        _locError = 'Location error: $e';
      } finally {
        setState(() {
          _locLoading = false;
          _useMyLocation = _locError == null;
        });
        _fetchInitialJobs();
      }
    } else {
      setState(() {
        _useMyLocation = false;
        _locError = null;
      });
      _fetchInitialJobs();
    }
  }

  Future<String?> _fetchCityFromCoords(double lat, double lon) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': '$lat',
        'lon': '$lon',
        'format': 'json',
      },
    );
    final resp = await http.get(
      uri,
      headers: {'User-Agent': 'jobmentor/1.0 (windows)'},
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>?;
      return addr?['city'] ??
          addr?['town'] ??
          addr?['village'] ??
          addr?['state'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (c, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _backgroundAnimation.value ?? Colors.blue.shade100,
                Colors.white
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildJobList(),
                    const ResumeBuilderScreen(),
                    CareerRoadmapScreen(),
                    const ProfileScreen(),
                  ],
                ),
              ),
              BottomNavigationBar(
                backgroundColor: Colors.white,
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
                currentIndex: _selectedIndex,
                type: BottomNavigationBarType.fixed,
                elevation: 10,
                showUnselectedLabels: true,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.work), label: 'Jobs'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.article), label: 'Resume'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.timeline), label: 'Roadmap'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Your Dream Job',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search for jobs...',
              prefixIcon:
                  const Icon(Icons.search, color: Colors.blue),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter by my location'),
              Switch(
                value: _useMyLocation,
                onChanged: _toggleUseMyLocation,
                activeColor: Colors.blue,
              ),
            ],
          ),
          if (_locLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(),
            ),
          if (_locError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(_locError!,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (_useMyLocation && _userCity != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text('Showing jobs in: $_userCity'),
            ),
          const SizedBox(height: 20),
          const Text(
            'Recommended Jobs',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                    ? Center(
                        child: Text(error,
                            style:
                                const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        itemCount: filteredJobs.length,
                        itemBuilder: (c, idx) {
                          final job = filteredJobs[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.work,
                                  color: Colors.blue),
                              title: Text(job.title,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold)),
                              subtitle: Text(
                                  '${job.company} - ${job.location}'),
                              trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.blue),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          JobDetailsScreen(
                                              job: job)),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
