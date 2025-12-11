export type Provider = 'claude' | 'openai' | 'gemini';

export type ClaudeModel = 'claude-sonnet-4-20250514' | 'claude-opus-4-20250514' | 'claude-haiku-3-5-20241022';
export type OpenAIModel = 'gpt-4o' | 'gpt-4o-mini' | 'gpt-4-turbo';
export type GeminiModel = 'gemini-2.0-flash' | 'gemini-1.5-pro' | 'gemini-1.5-flash';
export type Model = ClaudeModel | OpenAIModel | GeminiModel;

export interface ModelOption {
  value: Model;
  label: string;
}

export const modelsByProvider: Record<Provider, ModelOption[]> = {
  claude: [
    { value: 'claude-sonnet-4-20250514', label: 'Claude Sonnet 4' },
    { value: 'claude-opus-4-20250514', label: 'Claude Opus 4' },
    { value: 'claude-haiku-3-5-20241022', label: 'Claude Haiku 3.5' },
  ],
  openai: [
    { value: 'gpt-4o', label: 'GPT-4o' },
    { value: 'gpt-4o-mini', label: 'GPT-4o Mini' },
    { value: 'gpt-4-turbo', label: 'GPT-4 Turbo' },
  ],
  gemini: [
    { value: 'gemini-2.0-flash', label: 'Gemini 2.0 Flash' },
    { value: 'gemini-1.5-pro', label: 'Gemini 1.5 Pro' },
    { value: 'gemini-1.5-flash', label: 'Gemini 1.5 Flash' },
  ],
};

export const defaultModels: Record<Provider, Model> = {
  claude: 'claude-sonnet-4-20250514',
  openai: 'gpt-4o',
  gemini: 'gemini-2.0-flash',
};

export interface QueryResponse {
  response: string;
  provider: string;
  model: string;
}

const API_BASE = import.meta.env.PROD
  ? '' // In production, worker is at same origin
  : ''; // In dev, proxied via vite to localhost:8787

export async function queryApi(
  image: string,
  prompt: string,
  provider: Provider,
  model?: Model
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
      model,
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || `HTTP ${response.status}`);
  }

  return response.json();
}
