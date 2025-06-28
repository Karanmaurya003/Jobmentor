class Job {
  final String title;
  final String company;
  final String location;
  final String description;
  final String applyLink;

  Job({
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.applyLink,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      title: json['job_title'] ?? 'N/A',
      company: json['employer_name'] ?? 'Unknown Company',
      location: json['job_city'] ?? 'Unknown',
      description: json['job_description'] ?? 'No description available',
      applyLink: json['job_apply_link'] ?? '',
    );
  }
}
