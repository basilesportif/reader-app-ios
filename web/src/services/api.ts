export type Provider = 'claude' | 'openai' | 'gemini';

export interface QueryResponse {
  response: string;
  provider: string;
  model: string;
}

const API_BASE = import.meta.env.PROD 
  ? '' // In production, worker is at same origin
  : '/api'; // In dev, proxied via vite

export async function queryApi(
  image: string,
  prompt: string,
  provider: Provider
): Promise<QueryResponse> {
  const response = await fetch(`${API_BASE}/api/query`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      image,
      prompt,
      provider,
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || `HTTP ${response.status}`);
  }

  return response.json();
}
