import {setGlobalOptions} from "firebase-functions";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {matchingFlow} from "./matching";

setGlobalOptions({ maxInstances: 10 });

export const matchStudentToOpportunity = onCall(
  { 
    secrets: ["GOOGLE_GENAI_API_KEY"],
    // enforceAppCheck: false, // TODO: Set to true once App Check is enabled in the Firebase Console and client apps
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in to use AI matching.');
    }
    return await matchingFlow(request.data);
  }
);
