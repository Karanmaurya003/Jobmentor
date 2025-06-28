import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job.dart';

class JobApiService {
  /// Fetch jobs matching [query], optionally restricted to [location].
  static Future<List<Job>> fetchJobs(String query, {String? location}) async {
    // Build a combined free‑text query: “developer in Bangalore”
    var q = query;
    if (location != null && location.isNotEmpty) {
      q = '$query in $location';
    }
    final encoded = Uri.encodeComponent(q);
    final url = 'https://jsearch.p.rapidapi.com/search?query=$encoded&num_pages=1';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'X-RapidAPI-Key': 'YOUR-RAPID-API-KEY',
        'X-RapidAPI-Host': 'jsearch.p.rapidapi.com',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List jobsData = data['data'] as List;
      return jobsData.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load jobs (status ${response.statusCode})');
    }
  }
}
