import { Timestamp } from 'firebase-admin/firestore';

export interface ExternalJob {
  id?: string;
  source: string; // e.g. 'jsearch'
  externalId: string; // the job's id from the API
  title: string;
  company: string;
  description: string;
  location: string;
  jobType: 'job' | 'internship';
  requiredSkills: string[];
  applyUrl: string;
  postedAt: Timestamp;
  createdAt: Timestamp; // server timestamp
}

export interface ExternalJobMatch {
  studentId: string;
  jobId: string;
  score: number; // 0-100
  explanation: string;
  matched_skills: string[];
  missing_skills: string[];
  createdAt: Timestamp;
}

export interface CvEnhancement {
  id?: string;
  studentId: string;
  jobId: string; // references external_jobs or opportunities
  jobSource: 'external' | 'internal';
  originalText: string;
  enhancedText: string;
  improvedBullets: { original: string; improved: string }[];
  addedKeywords: string[];
  createdAt: Timestamp;
}

export interface StartupPlan {
  id?: string;
  startupId: string;
  ideaText: string;
  legalRequirements: { step: string; authority: string; estimatedCostAed: number; notes: string }[];
  recommendedStructure: string;
  timelineMilestones: { phase: string; milestone: string; tasks: any[] }[];
  recentNews: { headline: string; whyItMatters: string; source: string }[];
  risks: string[];
  createdAt: Timestamp;
}

export interface JobPreferences {
  location: string;
  jobTypes: string[];
  industries: string[];
  availability: string;
}
