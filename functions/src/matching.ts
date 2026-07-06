import { genkit, z } from 'genkit';
import { googleAI } from '@genkit-ai/googleai';

export const ai = genkit({
  plugins: [googleAI()],
  model: 'googleai/gemini-2.5-flash',
});

export const matchingFlow = ai.defineFlow(
  {
    name: 'matchingFlow',
    inputSchema: z.object({
      student: z.object({
        name: z.string().max(100),
        major: z.string().max(100),
        skills: z.record(z.string().max(50), z.number().min(0).max(100)),
      }),
      opportunity: z.object({
        title: z.string().max(200),
        description: z.string().max(2000),
        requiredSkills: z.array(z.string().max(50)).max(20),
        duration: z.string().max(100),
      }),
    }),
    outputSchema: z.object({
      score: z.number(),
      explanation: z.string(),
      matched_skills: z.array(z.string()),
      missing_skills: z.array(z.string()),
    }),
  },
  async (input) => {
    console.log('Matching flow input:', JSON.stringify(input));
    const studentSkillsSummary = Object.entries(input.student.skills)
      .map(([skill, proficiency]) => `${skill} (${proficiency}% proficiency)`)
      .join(', ');

    const prompt = `
You are a talent matching AI for Bidaya, a student-startup matching platform.

Evaluate how well this student matches the opportunity.

STUDENT PROFILE:
- Name: ${input.student.name}
- Field/Major: ${input.student.major}
- Skills: ${studentSkillsSummary || 'Not specified'}

OPPORTUNITY:
- Title: ${input.opportunity.title}
- Description: ${input.opportunity.description}
- Required Skills: ${input.opportunity.requiredSkills.join(', ')}
- Duration: ${input.opportunity.duration}
`;

    const response = await ai.generate({
      prompt,
      output: {
        schema: z.object({
          score: z.number().describe('0-100 matching score'),
          explanation: z.string().describe('1-2 sentence explanation'),
          matched_skills: z.array(z.string()),
          missing_skills: z.array(z.string()),
        }),
      },
    });

    if (!response.output) {
      console.error('AI failed to generate matching output. Raw response:', JSON.stringify(response));
      throw new Error('AI failed to generate matching output');
    }

    console.log('Matching flow output:', JSON.stringify(response.output));
    return response.output;
  }
);
