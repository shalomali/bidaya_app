class StartupProfileModel {
  final String uid;
  final String companyName;
  final String description;
  final String? website;
  final String? industry;
  final String? workType; // Remote, Hybrid, In-Person
  final String? stage;    // Seed, Series A, MVP, etc.

  StartupProfileModel({
    required this.uid,
    required this.companyName,
    required this.description,
    this.website,
    this.industry,
    this.workType,
    this.stage,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'companyName': companyName,
      'description': description,
      'website': website,
      'industry': industry,
      'workType': workType,
      'stage': stage,
    };
  }

  factory StartupProfileModel.fromMap(Map<String, dynamic> map) {
    return StartupProfileModel(
      uid: map['uid'] ?? '',
      companyName: map['companyName'] ?? '',
      description: map['description'] ?? '',
      website: map['website'],
      industry: map['industry'],
      workType: map['workType'],
      stage: map['stage'],
    );
  }
}
