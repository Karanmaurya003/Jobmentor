import 'dart:io';  
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/career_paths_data.dart';
import '../services/career_progress_service.dart';
import '../widgets/career_step_tile.dart';
import 'package:flutter/foundation.dart';



class CareerRoadmapScreen extends StatefulWidget {
  const CareerRoadmapScreen({Key? key}) : super(key: key);

  @override
  _CareerRoadmapScreenState createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen>
    with TickerProviderStateMixin {
  final CareerProgressService _progressService = CareerProgressService();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Static and custom career paths
  final List<CareerPath> _staticPaths = careerPathsData;
  List<CareerPath> _customPaths = [];
  List<CareerPath> _allPaths = [];

  String _sortOrder = 'A-Z';

  // Icon options for custom steps
  final Map<String, IconData> _iconOptions = {
    'Code': Icons.code,
    'Build': Icons.build,
    'Business': Icons.business_center,
    'Analytics': Icons.analytics,
    'Security': Icons.security,
    'Science': Icons.science,
    'Design': Icons.design_services,
    'Cloud': Icons.cloud,
  };

  // Animation controllers
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _colorController;
  late final Animation<Color?> _backgroundColor;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _backgroundColor = ColorTween(
      begin: Colors.blue.shade50,
      end: Colors.purple.shade100,
    ).animate(_colorController);

    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserProgress();
    await _loadCustomPaths();
    _mergePaths();
  }


  /// Loads detailed user progress and merges into CareerStep models
  Future<void> _loadUserProgress() async {
    final data = await _progressService.getFullUserProgress();
    for (final path in [..._staticPaths, ..._customPaths]) {
      for (final step in path.steps) {
        final docId = '${path.title}_${step.title}'.replaceAll(' ', '_');
        if (data.containsKey(docId)) {
          final map = data[docId]!;
          step.completed = map['completed'] as bool;
          step.notes = map['notes'] as String;
          step.firstAccessed = map['firstAccessed'] as DateTime?;
          step.lastUpdated = map['lastUpdated'] as DateTime?;
        }
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  /// Loads user-defined custom career paths from Firestore
  Future<void> _loadCustomPaths() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _db.collection('userCareerPaths').doc(uid).get();
    if (!doc.exists) return;
    final list = doc.data()?['paths'] as List<dynamic>?;
    if (list == null) return;

    _customPaths = list.map((m) {
      final steps = (m['steps'] as List<dynamic>).map((s) {
        return CareerStep(
          title: s['title'],
          description: s['description'],
          skillsRequired: s['skillsRequired'],
          resources: s['resources'],
          icon: _iconOptions[s['iconKey']] ?? Icons.code,
          studyLink: s['studyLink'],
        );
      }).toList();
      return CareerPath(title: m['title'], steps: steps);
    }).toList();
  }

  /// Saves custom paths back to Firestore
  Future<void> _saveCustomPaths() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final data = _customPaths.map((p) {
      return {
        'title': p.title,
        'steps': p.steps.map((s) {
          return {
            'title': s.title,
            'description': s.description,
            'skillsRequired': s.skillsRequired,
            'resources': s.resources,
            'iconKey': _iconOptions.entries
                .firstWhere((e) => e.value == s.icon,
                    orElse: () => const MapEntry('Code', Icons.code))
                .key,
            'studyLink': s.studyLink,
          };
        }).toList(),
      };
    }).toList();
    await _db.collection('userCareerPaths').doc(uid).set({'paths': data});
  }

  void _mergePaths() {
    _allPaths = [..._staticPaths, ..._customPaths];
    _sortPaths();
    if (!mounted) return;
    setState(() {});
  }

  void _sortPaths() {
    _allPaths.sort((a, b) => _sortOrder == 'A-Z'
        ? a.title.compareTo(b.title)
        : b.title.compareTo(a.title));
  }

  void _filterPaths(String query) {
    final all = [..._staticPaths, ..._customPaths];
    _allPaths = all
        .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    _sortPaths();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _addNewPath() async {
    final title = await _showInputDialog('Add New Career Path');
    if (title != null && title.isNotEmpty) {
      _customPaths.add(CareerPath(title: title, steps: []));
      await _saveCustomPaths();
      _mergePaths();
    }
  }

  Future<void> _deletePath(CareerPath path) async {
    _customPaths.removeWhere((p) => p.title == path.title);
    await _saveCustomPaths();
    _mergePaths();
  }

  /// Dialog to add a new step
  Future<void> _showAddStepDialog(CareerPath career) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final skillsCtrl = TextEditingController();
    final resourcesCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String selectedIconKey = _iconOptions.keys.first;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Add New Step'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Step Title')),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(controller: skillsCtrl, decoration: const InputDecoration(labelText: 'Skills Required')),
                  TextField(controller: resourcesCtrl, decoration: const InputDecoration(labelText: 'Resources')),
                  TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Study Link (URL)')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedIconKey,
                    decoration: const InputDecoration(labelText: 'Select Icon'),
                    items: _iconOptions.keys.map((key) {
                      return DropdownMenuItem(
                        value: key,
                        child: Row(children: [Icon(_iconOptions[key]), const SizedBox(width: 8), Text(key)]),
                      );
                    }).toList(),
                    onChanged: (val) => setStateDialog(() => selectedIconKey = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    career.steps.add(CareerStep(
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      skillsRequired: skillsCtrl.text,
                      resources: resourcesCtrl.text,
                      icon: _iconOptions[selectedIconKey]!,
                      studyLink: linkCtrl.text,
                    ));
                    if (_customPaths.any((p) => p.title == career.title)) {
                      _saveCustomPaths();
                      _mergePaths();
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Step'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog to input a single line of text
  Future<String?> _showInputDialog(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _colorController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundColor,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Career Roadmap', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blueAccent,
            actions: [
              DropdownButton<String>(
                value: _sortOrder,
                items: const [
                  DropdownMenuItem(value: 'A-Z', child: Text('Sort A-Z')),
                  DropdownMenuItem(value: 'Z-A', child: Text('Sort Z-A')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _sortOrder = v;
                  _mergePaths();
                },
                underline: const SizedBox(),
                icon: const Icon(Icons.sort, color: Colors.white),
                dropdownColor: Colors.white,
              ),
              IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _addNewPath),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_backgroundColor.value!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Career Paths',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: _filterPaths,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allPaths.length,
                      itemBuilder: (context, index) {
                        final path = _allPaths[index];
                        final total = path.steps.length;
                        final completedCount = path.steps.where((s) => s.completed).length;
                        final progress = total > 0 ? completedCount / total : 0.0;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(path.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey.shade300,
                                          color: Colors.blueAccent,
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_customPaths.any((p) => p.title == path.title))
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deletePath(path)),
                              ],
                            ),
                            children: [
                              // Wrapped each step in its own ExpansionTile for timing
                              ...path.steps.map((step) {
                                final docId = '${path.title}_${step.title}'.replaceAll(' ', '_');
                                return ExpansionTile(
                                  title: Text(step.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  children: [
                                    CareerStepTile(
                                      step: step,
                                      isCompleted: step.completed,
                                      notes: step.notes,
                                      
                                      lastUpdated: step.lastUpdated,
                                      firstAccessed: step.firstAccessed,
                                      onChanged: (val) async {
                                        if (!val && step.completed) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved progress cannot be undone')));
                                          return;
                                        }
                                        await _progressService.updateUserProgress(
                                          step: docId,
                                          isCompleted: val,
                                          notes: step.notes,
                                          
                                        );
                                        if (mounted) {
                                          setState(() => step.completed = val);
                                        }
                                      },
                                    ),
                                  ],
                                );
                              }).toList(),
                              ListTile(
                                leading: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                                title: const Text('Add Step'),
                                onTap: () => _showAddStepDialog(path),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

