import {setGlobalOptions} from "firebase-functions";
import {onCall} from "firebase-functions/v2/https";
import {matchingFlow} from "./matching";

setGlobalOptions({ maxInstances: 10 });

export const matchStudentToOpportunity = onCall(
  { secrets: ["GOOGLE_GENAI_API_KEY"] },
  async (request) => {
    return await matchingFlow(request.data);
  }
);
