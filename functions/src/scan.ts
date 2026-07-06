import { genkit, z } from 'genkit';
import { googleAI } from '@genkit-ai/googleai';

export const ai = genkit({
  plugins: [googleAI()],
  model: 'googleai/gemini-2.5-flash',
});

export const scanFlow = ai.defineFlow(
  {
    name: 'scanFlow',
    inputSchema: z.object({
      cvBase64: z.string(),
      cvMimeType: z.string(),
      portfolioText: z.string().optional(),
    }),
    outputSchema: z.object({
      skills: z.record(z.string(), z.number()),
      hidden_signals: z.array(z.string()),
      profile_completeness_pct: z.number(),
    }),
  },
  async (input) => {
    const promptParts: any[] = [
      {
        text: `You are a professional profile reviewer for Bidaya. 
Analyze the student's CV and optional portfolio text to extract their skills with proficiency levels (0-100), notable work/hidden signals, and calculate their profile completeness percentage (0-100).

Make sure to merge, analyze, and return the data EXACTLY in this JSON format:
{
  "skills": { "skillName": 0-100, ... },
  "hidden_signals": ["signal1", "signal2", ...],
  "profile_completeness_pct": 0-100
}
`
      }
    ];

    promptParts.push({
      media: {
        url: `data:${input.cvMimeType};base64,${input.cvBase64}`,
        contentType: input.cvMimeType,
      }
    });

    if (input.portfolioText) {
      promptParts.push({
        text: `Here is the student's portfolio website HTML content (extracted raw text):\n\n${input.portfolioText}`
      });
    }

    const response = await ai.generate({
      prompt: promptParts,
      output: {
        schema: z.object({
          skills: z.record(z.string(), z.number()),
          hidden_signals: z.array(z.string()),
          profile_completeness_pct: z.number(),
        }),
      },
    });

    if (!response.output) {
      throw new Error('AI failed to generate scan output');
    }

    return response.output;
  }
);
