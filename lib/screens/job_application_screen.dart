import 'package:flutter/material.dart';

class JobApplicationScreen extends StatefulWidget {
  final String jobTitle;

  const JobApplicationScreen({super.key, required this.jobTitle});

  @override
  _JobApplicationScreenState createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController resumeController = TextEditingController();

  void _submitApplication() {
    if (_formKey.currentState!.validate()) {
      // Normally, we would send this data to a backend API.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application submitted for ${widget.jobTitle}'),
        ),
      );
      // Clear form fields after submission
      nameController.clear();
      emailController.clear();
      resumeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Apply for ${widget.jobTitle}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$")
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: resumeController,
                decoration: const InputDecoration(labelText: 'Resume Link'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a resume link';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitApplication,
                child: const Text('Submit Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
