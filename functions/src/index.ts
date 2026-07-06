import {setGlobalOptions} from "firebase-functions";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from 'firebase-admin';
import {matchingFlow} from "./matching";
import {scanFlow} from "./scan";

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

export const matchStudentToOpportunity = onCall(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in to use AI matching.');
    }
    return await matchingFlow(request.data);
  }
);

export const scanCvAndPortfolio = onCall(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in to use AI CV scanning.');
    }

    const studentId = request.data.studentId;
    if (!studentId || typeof studentId !== 'string') {
      throw new HttpsError('invalid-argument', 'studentId is required and must be a string.');
    }

    if (request.auth.uid !== studentId) {
      throw new HttpsError('permission-denied', 'You can only scan your own CV and portfolio.');
    }

    const db = admin.firestore();
    const profileRef = db.collection('student_profiles').doc(studentId);
    const profileDoc = await profileRef.get();
    if (!profileDoc.exists) {
      throw new HttpsError('not-found', 'Student profile not found.');
    }

    const profileData = profileDoc.data();
    const cvUrl = profileData?.cvUrl;
    const cvFileType = profileData?.cvFileType;
    const portfolioUrl = profileData?.portfolioUrl;

    if (!cvUrl) {
      throw new HttpsError('failed-precondition', 'Please upload a CV before scanning.');
    }

    // Download CV from Cloud Storage
    let fileBuffer: Buffer;
    let mimeType = 'application/pdf';
    try {
      const bucket = admin.storage().bucket();
      const [files] = await bucket.getFiles({ prefix: `cvs/${studentId}/` });
      if (files.length === 0) {
        throw new Error('No CV files found in storage folder.');
      }
      const cvFile = files[0];
      const [buffer] = await cvFile.download();
      fileBuffer = buffer;
      
      if (cvFileType === 'image') {
        const ext = cvFile.name.split('.').pop()?.toLowerCase();
        if (ext === 'png') {
          mimeType = 'image/png';
        } else {
          mimeType = 'image/jpeg';
        }
      }
    } catch (err: any) {
      console.error('Error downloading CV from Storage:', err);
      throw new HttpsError('internal', `Failed to download CV file from Storage: ${err.message}`);
    }

    if (fileBuffer.length > 5 * 1024 * 1024) {
      throw new HttpsError('invalid-argument', 'CV file size exceeds limit of 5MB.');
    }

    let portfolioText = "";
    if (portfolioUrl) {
      try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 6000);
        const res = await fetch(portfolioUrl, { signal: controller.signal });
        clearTimeout(timeout);
        if (res.ok) {
          const html = await res.text();
          portfolioText = html.substring(0, 30000);
        }
      } catch (err) {
        console.warn(`Failed to fetch portfolio URL: ${portfolioUrl}`, err);
      }
    }

    let result;
    try {
      result = await scanFlow({
        cvBase64: fileBuffer.toString('base64'),
        cvMimeType: mimeType,
        portfolioText: portfolioText || undefined,
      });
    } catch (err: any) {
      console.error('Genkit execution failed:', err);
      throw new HttpsError('internal', `AI execution failed: ${err.message}`);
    }

    const generatedSkills = result.skills || {};
    const currentSkills = profileData?.skills || {};
    const mergedSkills = { ...currentSkills };

    for (const [skillName, genValue] of Object.entries(generatedSkills)) {
      const existingKey = Object.keys(currentSkills).find(
        (k) => k.toLowerCase() === skillName.toLowerCase()
      );
      
      const genNum = typeof genValue === 'number' ? genValue : 50;
      
      if (existingKey) {
        const existingVal = currentSkills[existingKey];
        mergedSkills[existingKey] = Math.round((existingVal + genNum) / 2);
      } else {
        const formattedName = skillName.split(' ')
          .map(w => w.charAt(0).toUpperCase() + w.slice(1))
          .join(' ');
        mergedSkills[formattedName] = genNum;
      }
    }

    await profileRef.update({ skills: mergedSkills });

    return {
      skills: generatedSkills,
      hidden_signals: result.hidden_signals || [],
      profile_completeness_pct: result.profile_completeness_pct || 0,
    };
  }
);
