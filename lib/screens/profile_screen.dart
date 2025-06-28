import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jobmentor/services/auth_service.dart';
import 'package:jobmentor/screens/login_view.dart';
import 'package:mime/mime.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  firebase_auth.User? _user;
  String? _profileImageUrl;
  String? _profileImagePath;

  final ImagePicker _picker = ImagePicker();

  String? selectedCareer;
  final List<String> careerOptions = [
    'Software Developer',
    'Data Scientist',
    'Cybersecurity Analyst',
    'Product Manager',
    'UI/UX Designer',
  ];

  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;
  late AnimationController _cardFadeController;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();
    _authService.userChanges.listen((firebase_auth.User? user) {
      if (mounted) {
        setState(() {
          _user = user;
          if (_user != null) {
            nameController.text = _user!.displayName ?? "User";
            emailController.text = _user!.email ?? "No email";
            _loadUserProfile();
          }
        });
      }
    });

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Colors.blue.shade100,
      end: Colors.purple.shade100,
    ).animate(_backgroundController);

    _cardFadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardFadeController, curve: Curves.easeIn),
    );
    _cardFadeController.forward();
  }

  @override
  void dispose() {
    _backgroundController.stop();
    _backgroundController.dispose();
    _cardFadeController.stop();
    _cardFadeController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    locationController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;
    final userRef = FirebaseFirestore.instance.collection("users").doc(_user!.uid);
    final userDoc = await userRef.get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('profileImage')) {
        await userRef.set({'profileImage': ''}, SetOptions(merge: true));
      }
      setState(() {
        phoneController.text = data?['phone'] ?? '';
        bioController.text = data?['bio'] ?? '';
        locationController.text = data?['location'] ?? '';
        skillsController.text = data?['skills'] ?? '';
        selectedCareer = data?['career'] ?? careerOptions.first;
        final rawUrl = data?['profileImage'] as String?;
        _profileImageUrl = (rawUrl != null && rawUrl.isNotEmpty) ? rawUrl : null;
        _profileImagePath = data?['profileImagePath'] as String?;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;
    try {
      await _user!.updateDisplayName(nameController.text);
      await FirebaseFirestore.instance.collection("users").doc(_user!.uid).set({
        "displayName": nameController.text,
        "phone": phoneController.text,
        "bio": bioController.text,
        "location": locationController.text,
        "skills": skillsController.text,
        "career": selectedCareer,
        "profileImage": _profileImageUrl ?? '',
        "profileImagePath": _profileImagePath,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || _user == null) return;

    final file = File(pickedFile.path);
    final userId = _user!.uid;
    final fileExt = pickedFile.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'profile_images/$userId-$timestamp.$fileExt';

    try {
      final supabase = Supabase.instance.client;
      final bucket = supabase.storage.from('avatars');

      final mimeType = lookupMimeType(file.path);
      final fileOptions = FileOptions(upsert: true, contentType: mimeType);

      final fileBytes = await file.readAsBytes();
      await bucket.uploadBinary(filePath, fileBytes, fileOptions: fileOptions);

      final publicUrl = bucket.getPublicUrl(filePath);

      setState(() {
        _profileImageUrl = publicUrl;
        _profileImagePath = filePath;
      });

      await FirebaseFirestore.instance.collection("users").doc(_user!.uid).set({
        "profileImage": publicUrl,
        "profileImagePath": filePath,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
    } catch (e, st) {
      debugPrint('⚠️ UPLOAD ERROR: $e\n$st');
      final msg = e.toString().contains('violated row level security')
          ? 'Supabase policy violation (403). Check your storage RLS policies.'
          : 'Upload failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _deleteImage() async {
    if (_user == null || _profileImagePath == null) return;
    try {
      await Supabase.instance.client.storage
          .from('avatars')
          .remove([_profileImagePath!]);
      await FirebaseFirestore.instance.collection("users").doc(_user!.uid).set({
        "profileImage": '',
        "profileImagePath": FieldValue.delete(),
      }, SetOptions(merge: true));
      setState(() {
        _profileImageUrl = null;
        _profileImagePath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image deleted successfully!')),
      );
    } catch (e, st) {
      debugPrint('⚠️ DELETE ERROR: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundAnimation.value,
          appBar: AppBar(
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                )],
              ),
              child: const Text('My Profile', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white
              )),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginView()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Stack(alignment: Alignment.center, children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage("assets/profile_placeholder.png")
                          as ImageProvider,
                  backgroundColor: Colors.grey[200],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.deepPurple),
                    onPressed: _uploadImage,
                  ),
                ),
                if (_profileImageUrl != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteImage,
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _cardFadeAnimation,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(children: [
                      _buildTextField(nameController, "Full Name"),
                      _buildTextField(emailController, "Email Address", enabled: false),
                      _buildTextField(phoneController, "Phone Number"),
                      _buildTextField(bioController, "Bio"),
                      _buildTextField(locationController, "Location"),
                      _buildTextField(skillsController, "Skills"),
                      DropdownButtonFormField<String>(
                        value: selectedCareer,
                        items: careerOptions.map((career) {
                          return DropdownMenuItem(
                            value: career,
                            child: Text(career),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: "Career Goal",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() => selectedCareer = value!),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Save", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        enabled: enabled,
      ),
    );
  }
}
