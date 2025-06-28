// All necessary imports
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({Key? key}) : super(key: key);

  @override
  _ResumeBuilderScreenState createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final List<TextEditingController> experienceControllers = [];
  final List<TextEditingController> educationControllers = [];
  final List<TextEditingController> additionalControllers = [];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    summaryController.dispose();
    skillsController.dispose();
    for (var c in experienceControllers) c.dispose();
    for (var c in educationControllers) c.dispose();
    for (var c in additionalControllers) c.dispose();
    super.dispose();
  }

  void addExperienceField() {
    setState(() {
      experienceControllers.add(TextEditingController());
    });
  }

  void removeExperienceField(int index) {
    setState(() {
      experienceControllers[index].dispose();
      experienceControllers.removeAt(index);
    });
  }

  void addEducationField() {
    setState(() {
      educationControllers.add(TextEditingController());
    });
  }

  void removeEducationField(int index) {
    setState(() {
      educationControllers[index].dispose();
      educationControllers.removeAt(index);
    });
  }

  void addAdditionalField() {
    setState(() {
      additionalControllers.add(TextEditingController());
    });
  }

  void removeAdditionalField(int index) {
    setState(() {
      additionalControllers[index].dispose();
      additionalControllers.removeAt(index);
    });
  }

  Future<void> generateResume() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdk = androidInfo.version.sdkInt;
      if (sdk >= 33) {
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Manage External Storage permission is required.')),
          );
          return;
        }
      } else {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Storage permission is required to save the resume.')),
          );
          return;
        }
      }
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final skills = skillsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Resume',
                  style: pw.TextStyle(
                      fontSize: 32, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Personal Information',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Name: ${nameController.text}'),
              pw.Text('Email: ${emailController.text}'),
              pw.Text('Phone: ${phoneController.text}'),
              pw.SizedBox(height: 20),
              pw.Text('Summary',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text(summaryController.text),
              pw.SizedBox(height: 20),
              pw.Text('Skills',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((skill) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                              color: PdfColors.blue,
                              borderRadius: pw.BorderRadius.circular(5)),
                          child: pw.Text(skill,
                              style: pw.TextStyle(color: PdfColors.white)),
                        ))
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              if (experienceControllers.isNotEmpty) ...[
                pw.Text('Experience',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                ...experienceControllers.map(
                    (c) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Text(c.text))),
                pw.SizedBox(height: 20),
              ],
              if (educationControllers.isNotEmpty) ...[
                pw.Text('Education',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                ...educationControllers.map(
                    (c) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Text(c.text))),
                pw.SizedBox(height: 20),
              ],
              if (additionalControllers.isNotEmpty) ...[
                pw.Text('Additional Information',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                ...additionalControllers.map(
                    (c) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Text(c.text))),
                pw.SizedBox(height: 20),
              ],
              pw.Spacer(),
              pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Generated by JobMentor',
                      style: pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey)))
            ],
          );
        },
      ),
    );

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getDownloadsDirectory();
    }

    if (directory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find a valid directory')));
      return;
    }

    final file = File('${directory.path}/resume.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade300, Colors.purple.shade300],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 700),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Resume Builder',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(color: Colors.black45, blurRadius: 5)
                                          ])),
                                  const SizedBox(height: 20),
                                  Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          _buildTextField(nameController, 'Full Name'),
                                          _buildTextField(emailController, 'Email'),
                                          _buildTextField(phoneController, 'Phone Number'),
                                          _buildTextField(summaryController, 'Summary'),
                                          _buildTextField(skillsController, 'Skills (comma-separated)'),
                                          ..._buildDynamicFields(experienceControllers, 'Experience', removeExperienceField),
                                          ElevatedButton(onPressed: addExperienceField, child: const Text('Add Experience')),
                                          ..._buildDynamicFields(educationControllers, 'Education', removeEducationField),
                                          ElevatedButton(onPressed: addEducationField, child: const Text('Add Education')),
                                          ..._buildDynamicFields(additionalControllers, 'Additional Info', removeAdditionalField),
                                          ElevatedButton(onPressed: addAdditionalField, child: const Text('Add More Sections')),
                                          const SizedBox(height: 20),
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              SizedBox(
                                                width: width > 500 ? 250 : width * 0.8,
                                                child: ElevatedButton(
                                                  onPressed: generateResume,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.purple.shade400,
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10)),
                                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'Generate Resume',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: width > 500 ? 250 : width * 0.8,
                                                child: ElevatedButton(
                                                  onPressed: generateResume,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blue.shade400,
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10)),
                                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'Download Resume',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields(List<TextEditingController> controllers, String label, Function(int) onRemove) {
    return List.generate(controllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Expanded(
              child: _buildTextField(controllers[index], '$label ${index + 1}'),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => onRemove(index),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
