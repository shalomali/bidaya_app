class StudentProfileModel {
  final String uid;
  final String name;
  final String university;
  final String major;
  final String email;
  final Map<String, double> skills;
  final String cvUrl;
  final String? cvFileName; // Optional metadata
  final String? cvFileType; // New: pdf, jpg, png
  final String? bio;        // New optional bio
  final String? portfolioUrl; // New optional portfolio link
  final List<String> bookmarks; // New bookmark IDs

  StudentProfileModel({
    required this.uid,
    required this.name,
    required this.university,
    required this.major,
    required this.email,
    required this.skills,
    required this.cvUrl,
    this.cvFileName,
    this.cvFileType,
    this.bio,
    this.portfolioUrl,
    this.bookmarks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'university': university,
      'major': major,
      'email': email,
      'skills': skills,
      'cvUrl': cvUrl,
      'cvFileName': cvFileName,
      'cvFileType': cvFileType,
      'bio': bio,
      'portfolioUrl': portfolioUrl,
      'bookmarks': bookmarks,
    };
  }

  factory StudentProfileModel.fromMap(Map<String, dynamic> map) {
    // Map skill values safely to double (handle int vs double on native)
    final mapSkills = map['skills'] as Map<dynamic, dynamic>? ?? {};
    final skills = mapSkills.map((key, value) => MapEntry(key.toString(), (value as num).toDouble()));

    return StudentProfileModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      university: map['university'] ?? '',
      major: map['major'] ?? '',
      email: map['email'] ?? '',
      skills: skills,
      cvUrl: map['cvUrl'] ?? '',
      cvFileName: map['cvFileName'],
      cvFileType: map['cvFileType'],
      bio: map['bio'],
      portfolioUrl: map['portfolioUrl'],
      bookmarks: List<String>.from(map['bookmarks'] ?? []),
    );
  }
}
