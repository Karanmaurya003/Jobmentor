import 'package:flutter/material.dart';

class CareerPath {
  final String title;
  final List<CareerStep> steps;

  CareerPath({required this.title, required this.steps});
}

class CareerStep {
  final String title;
  final String description;
  final String skillsRequired;
  final String resources;
  final IconData icon;
  final String studyLink;

  // New dynamic fields (not final)
  bool completed;
  double progressPercent;
  String notes;
  int timeSpent; // in seconds
  DateTime? firstAccessed;
  DateTime? lastUpdated;

  CareerStep({
    required this.title,
    required this.description,
    required this.skillsRequired,
    required this.resources,
    required this.icon,
    required this.studyLink,

    // Default values for dynamic fields
    this.completed = false,
    this.progressPercent = 0.0,
    this.notes = '',
    this.timeSpent = 0,
    this.firstAccessed,
    this.lastUpdated,
  });
}

final List<CareerPath> careerPathsData = [
  CareerPath(
    title: "Software Developer",
    steps: [
      CareerStep(
        title: "Learn Programming Basics",
        description: "Start with languages like Python, Java, or JavaScript.",
        skillsRequired: "Problem-solving, Logical Thinking, Debugging",
        resources: "Codecademy, freeCodeCamp, Udemy",
        icon: Icons.code,
        studyLink: "https://www.freecodecamp.org/",
      ),
      CareerStep(
        title: "Build Projects",
        description: "Work on small projects to strengthen coding skills.",
        skillsRequired: "Version Control (Git), Data Structures, Algorithms",
        resources: "GitHub, LeetCode, Hackerrank",
        icon: Icons.build,
        studyLink: "https://github.com/",
      ),
      CareerStep(
        title: "Apply for Internships",
        description: "Gain real-world experience by interning at companies.",
        skillsRequired: "Collaboration, Communication, API Development",
        resources: "LinkedIn, Internshala, AngelList",
        icon: Icons.business_center,
        studyLink: "https://internshala.com/",
      ),
    ],
  ),
  CareerPath(
    title: "Data Scientist",
    steps: [
      CareerStep(
        title: "Learn Python & Statistics",
        description: "Master Python, statistics, and machine learning basics.",
        skillsRequired: "Python, Probability, Data Visualization",
        resources: "Kaggle, Coursera, edX",
        icon: Icons.analytics,
        studyLink: "https://www.coursera.org/learn/python-data-analysis",
      ),
      CareerStep(
        title: "Work with Data",
        description: "Learn to clean, manipulate, and analyze data.",
        skillsRequired: "Pandas, SQL, NumPy",
        resources: "Kaggle Datasets, Mode Analytics, DataCamp",
        icon: Icons.dataset,
        studyLink: "https://www.kaggle.com/",
      ),
      CareerStep(
        title: "Build Machine Learning Models",
        description: "Develop predictive models using real-world datasets.",
        skillsRequired: "Scikit-Learn, TensorFlow, Model Deployment",
        resources: "Google Colab, TensorFlow Docs, Fast.ai",
        icon: Icons.science,
        studyLink: "https://www.fast.ai/",
      ),
    ],
  ),
  CareerPath(
    title: "Cybersecurity Analyst",
    steps: [
      CareerStep(
        title: "Learn Network Security",
        description: "Understand firewalls, VPNs, and cybersecurity fundamentals.",
        skillsRequired: "Networking, Ethical Hacking, Cryptography",
        resources: "CompTIA Security+, Cybrary, TryHackMe",
        icon: Icons.security,
        studyLink: "https://www.cybrary.it/",
      ),
      CareerStep(
        title: "Master Ethical Hacking",
        description: "Get hands-on experience with penetration testing.",
        skillsRequired: "Kali Linux, Penetration Testing, Threat Analysis",
        resources: "CEH Certification, Hack The Box, OWASP",
        icon: Icons.lock,
        studyLink: "https://www.hackthebox.com/",
      ),
      CareerStep(
        title: "Get Certified",
        description: "Earn industry certifications for job readiness.",
        skillsRequired: "CompTIA, CISSP, OSCP",
        resources: "ISC2, EC-Council, Offensive Security",
        icon: Icons.verified,
        studyLink: "https://www.offensive-security.com/",
      ),
    ],
  ),
  CareerPath(
    title: "UI/UX Designer",
    steps: [
      CareerStep(
        title: "Understand Design Principles",
        description: "Learn the basics of UX and UI design.",
        skillsRequired: "User Research, Wireframing, Prototyping",
        resources: "Adobe XD, Figma, UX Academy",
        icon: Icons.design_services,
        studyLink: "https://www.interaction-design.org/courses",
      ),
      CareerStep(
        title: "Master Design Tools",
        description: "Get hands-on experience with design software.",
        skillsRequired: "Figma, Adobe XD, Sketch",
        resources: "Dribbble, Behance, Udemy",
        icon: Icons.brush,
        studyLink: "https://www.figma.com/resources/learn-design/",
      ),
      CareerStep(
        title: "Build a Portfolio",
        description: "Create real-world UI/UX designs for your portfolio.",
        skillsRequired: "Usability Testing, Responsive Design, Typography",
        resources: "Dribbble, Medium, Coursera",
        icon: Icons.folder_open,
        studyLink: "https://www.behance.net/",
      ),
    ],
  ),
  CareerPath(
    title: "Digital Marketer",
    steps: [
      CareerStep(
        title: "Learn SEO & Content Marketing",
        description: "Understand how search engines work and create content.",
        skillsRequired: "SEO, Copywriting, Keyword Research",
        resources: "Google Digital Garage, HubSpot Academy, Moz",
        icon: Icons.trending_up,
        studyLink: "https://learndigital.withgoogle.com/digitalgarage",
      ),
      CareerStep(
        title: "Master Social Media Marketing",
        description: "Learn how to grow brands using social media.",
        skillsRequired: "Facebook Ads, Instagram Growth, Influencer Marketing",
        resources: "Facebook Blueprint, LinkedIn Learning, Hootsuite",
        icon: Icons.campaign,
        studyLink: "https://www.facebook.com/business/learn",
      ),
      CareerStep(
        title: "Work with Paid Ads",
        description: "Gain expertise in PPC and paid advertising.",
        skillsRequired: "Google Ads, Conversion Optimization, Analytics",
        resources: "Google Ads Academy, SEMrush, Ahrefs",
        icon: Icons.attach_money,
        studyLink: "https://ads.google.com/",
      ),
    ],
  ),
  CareerPath(
    title: "Cloud Engineer",
    steps: [
      CareerStep(
        title: "Learn Cloud Basics",
        description: "Understand cloud computing, storage, and networking.",
        skillsRequired: "AWS, GCP, Azure",
        resources: "AWS Academy, Google Cloud Labs, Microsoft Learn",
        icon: Icons.cloud,
        studyLink: "https://aws.amazon.com/training/",
      ),
      CareerStep(
        title: "Master DevOps Tools",
        description: "Work with cloud automation and deployment tools.",
        skillsRequired: "Docker, Kubernetes, Terraform",
        resources: "Udacity, Coursera, Pluralsight",
        icon: Icons.settings,
        studyLink: "https://www.udacity.com/course/cloud-dev-ops-nanodegree--nd9991",
      ),
      CareerStep(
        title: "Get Certified",
        description: "Earn cloud certifications to boost your resume.",
        skillsRequired: "AWS Certified, Google Cloud Associate, Azure Fundamentals",
        resources: "AWS Training, GCP Certifications, Azure Learn",
        icon: Icons.verified_user,
        studyLink: "https://aws.amazon.com/certification/",
      ),
    ],
  ),
];
