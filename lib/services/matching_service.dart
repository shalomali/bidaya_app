import '../models/student_profile_model.dart';
import '../models/opportunity_model.dart';

class MatchingService {
  /// Calculates a match percentage (0.0 to 1.0) based on skill intersection and proficiency.
  /// 
  /// Logic:
  /// 1. If no skills are required, return 1.0 (perfect match).
  /// 2. For each required skill:
  ///    - If student has it: proficiency / 100
  ///    - If student doesn't have it: 0.0
  /// 3. Average the proficiencies.
  double calculateMatchScore(StudentProfileModel student, OpportunityModel opportunity) {
    if (opportunity.requiredSkills.isEmpty) return 1.0;

    double totalProficiency = 0.0;
    
    for (String requiredSkill in opportunity.requiredSkills) {
      if (student.skills.containsKey(requiredSkill)) {
        totalProficiency += student.skills[requiredSkill]! / 100.0;
      }
    }

    return totalProficiency / opportunity.requiredSkills.length;
  }

  /// Helper to get a human-readable match string (e.g. "98%")
  String getMatchPercentage(StudentProfileModel student, OpportunityModel opportunity) {
    double score = calculateMatchScore(student, opportunity);
    return '${(score * 100).round()}%';
  }
}
