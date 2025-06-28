import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/career_paths_data.dart';

class CareerStepTile extends StatelessWidget {
  final CareerStep step;
  final bool isCompleted;
  final double progressPercent;
  final int? timeSpent; // in seconds
  final String? notes;
  final DateTime? lastUpdated;
  final DateTime? firstAccessed;
  final ValueChanged<bool> onChanged;

  const CareerStepTile({
    super.key,
    required this.step,
    required this.isCompleted,
    required this.onChanged,
    this.progressPercent = 100.0,
    this.timeSpent,
    this.notes,
    this.lastUpdated,
    this.firstAccessed,
  });

  void _launchURL(BuildContext context) async {
    final Uri uri = Uri.parse(step.studyLink ?? "");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch ${step.studyLink}")),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(step.icon, color: Colors.blueAccent),
              title: Text(
                step.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Description: ${step.description}", style: TextStyle(color: Colors.grey.shade700)),
                  Text("Skills Required: ${step.skillsRequired}", style: TextStyle(color: Colors.grey.shade600)),
                  Text("Resources: ${step.resources}", style: TextStyle(color: Colors.grey.shade600)),
                  if (step.studyLink != null && step.studyLink!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: GestureDetector(
                        onTap: () => _launchURL(context),
                        child: const Text(
                          "Free Study Material & Courses",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Progress bar (kept)
                  LinearProgressIndicator(
                    value: progressPercent / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: isCompleted ? Colors.green : Colors.orange,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  if (notes != null && notes!.isNotEmpty)
                    Text("Note: $notes", style: const TextStyle(fontStyle: FontStyle.italic)),
                  if (lastUpdated != null)
                    Text("Last Updated: ${_formatDate(lastUpdated)}"),
                  if (firstAccessed != null)
                    Text("First Accessed: ${_formatDate(firstAccessed)}"),
                ],
              ),
              trailing: Checkbox(
                value: isCompleted,
                activeColor: Colors.blueAccent,
                onChanged: (bool? value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
