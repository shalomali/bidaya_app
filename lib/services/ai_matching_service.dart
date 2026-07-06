import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/student_profile_model.dart';
import '../models/opportunity_model.dart';

class AIMatchResult {
  final int score; // 0-100
  final String explanation; // 1-2 sentence natural language rationale
  final List<String> matchedSkills;
  final List<String> missingSkills;

  const AIMatchResult({
    required this.score,
    required this.explanation,
    required this.matchedSkills,
    required this.missingSkills,
  });

  factory AIMatchResult.fallback(int score) {
    return AIMatchResult(
      score: score,
      explanation: 'Match calculated based on skill overlap.',
      matchedSkills: [],
      missingSkills: [],
    );
  }
}

class AIMatchingService {
  static final AIMatchingService _instance = AIMatchingService._internal();
  factory AIMatchingService() => _instance;
  AIMatchingService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Simple in-memory cache: key = "studentId_opportunityId"
  final Map<String, AIMatchResult> _cache = {};

  Future<AIMatchResult> getAIMatch(
    StudentProfileModel student,
    OpportunityModel opportunity,
  ) async {
    final cacheKey = '${student.uid}_${opportunity.id}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final result = await _callGemini(student, opportunity);
      _cache[cacheKey] = result;
      return result;
    } catch (e, stack) {
      debugPrint('🔴 AI matching failed for ${opportunity.title}: $e');
      debugPrint('Stack: $stack');
      // Fall back to deterministic score
      final opportunitySkills = opportunity.requiredSkills.map((s) => s.toLowerCase()).toList();
      final studentSkills = student.skills.keys.map((s) => s.toLowerCase()).toList();
      
      final matched = opportunitySkills
          .where((s) => studentSkills.contains(s))
          .toList();
          
      final fallbackScore = opportunitySkills.isEmpty
          ? 100
          : ((matched.length / opportunitySkills.length) * 100).round();
          
      final matchedStr = matched.isNotEmpty ? matched.join(', ') : 'none';
      final missing = opportunitySkills.where((s) => !studentSkills.contains(s)).toList();
      final missingStr = missing.isNotEmpty ? missing.join(', ') : 'none';

      String explanation = 'You match $fallbackScore% of the required skills.';
      if (matched.isNotEmpty) {
        explanation += ' Your proficiency in $matchedStr aligns well with this task.';
      }
      if (missing.isNotEmpty) {
        explanation += ' To improve your match, consider developing skills in: $missingStr.';
      }

      return AIMatchResult(
        score: fallbackScore,
        explanation: explanation,
        matchedSkills: matched,
        missingSkills: missing,
      );
    }
  }

  Future<AIMatchResult> _callGemini(
    StudentProfileModel student,
    OpportunityModel opportunity,
  ) async {
    final callable = _functions.httpsCallable('matchStudentToOpportunity');
    
    final response = await callable.call({
      'student': {
        'name': student.name,
        'major': student.major,
        'skills': student.skills,
      },
      'opportunity': {
        'title': opportunity.title,
        'description': opportunity.description,
        'requiredSkills': opportunity.requiredSkills,
        'duration': opportunity.duration,
      },
    });

    final data = response.data as Map<String, dynamic>;

    return AIMatchResult(
      score: (data['score'] as num).toInt().clamp(0, 100),
      explanation: data['explanation'] as String? ?? '',
      matchedSkills: List<String>.from(data['matched_skills'] ?? []),
      missingSkills: List<String>.from(data['missing_skills'] ?? []),
    );
  }

  Future<ScanResult> scanCvAndPortfolio(String studentId) async {
    final callable = _functions.httpsCallable('scanCvAndPortfolio');
    final response = await callable.call({'studentId': studentId});
    final data = response.data as Map<String, dynamic>;

    final rawSkills = data['skills'] as Map<dynamic, dynamic>? ?? {};
    final skills = rawSkills.map((key, value) => MapEntry(key.toString(), (value as num).toDouble()));

    return ScanResult(
      skills: skills,
      hiddenSignals: List<String>.from(data['hidden_signals'] ?? []),
      profileCompleteness: (data['profile_completeness_pct'] as num?)?.toInt() ?? 0,
    );
  }

  void clearCache() => _cache.clear();
}

class ScanResult {
  final Map<String, double> skills;
  final List<String> hiddenSignals;
  final int profileCompleteness;

  const ScanResult({
    required this.skills,
    required this.hiddenSignals,
    required this.profileCompleteness,
  });
}
