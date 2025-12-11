export type Provider = 'claude' | 'openai' | 'gemini';

export type ClaudeModel = 'claude-sonnet-4-5-20250929' | 'claude-opus-4-5-20251101';
export type OpenAIModel = 'gpt-5-mini' | 'gpt-5.1';
export type GeminiModel = 'gemini-2.5-flash' | 'gemini-3-pro-preview';
export type Model = ClaudeModel | OpenAIModel | GeminiModel;

export interface ModelOption {
  value: Model;
  label: string;
}

export const modelsByProvider: Record<Provider, ModelOption[]> = {
  claude: [
    { value: 'claude-sonnet-4-5-20250929', label: 'Claude Sonnet 4.5' },
    { value: 'claude-opus-4-5-20251101', label: 'Claude Opus 4.5' },
  ],
  openai: [
    { value: 'gpt-5.1', label: 'GPT-5.1' },
    { value: 'gpt-5-mini', label: 'GPT-5 Mini' },
  ],
  gemini: [
    { value: 'gemini-3-pro-preview', label: 'Gemini 3 Pro Preview' },
    { value: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash' },
  ],
};

export const defaultModels: Record<Provider, Model> = {
  claude: 'claude-sonnet-4-5-20250929',
  openai: 'gpt-5.1',
  gemini: 'gemini-3-pro-preview',
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
