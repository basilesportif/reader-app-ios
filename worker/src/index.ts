export interface Env {
  CLAUDE_API_KEY: string;
  OPENAI_API_KEY: string;
  GEMINI_API_KEY: string;
}

type Provider = 'claude' | 'openai' | 'gemini';

type ClaudeModel = 'claude-sonnet-4-5-20250929' | 'claude-opus-4-5-20251101';
type OpenAIModel = 'gpt-5-mini' | 'gpt-5.1';
type GeminiModel = 'gemini-2.5-flash' | 'gemini-3-pro-preview';
type Model = ClaudeModel | OpenAIModel | GeminiModel;

interface QueryRequest {
  image: string; // base64
  prompt: string;
  provider: Provider;
  model?: Model;
}

interface QueryResponse {
  response: string;
  provider: string;
  model: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (url.pathname === '/api/query' && request.method === 'POST') {
      try {
        const body: QueryRequest = await request.json();
        const { image, prompt, provider, model } = body;

        if (!image || !prompt || !provider) {
          return new Response(
            JSON.stringify({ error: 'Missing required fields: image, prompt, provider' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        const result = await queryProvider(provider, image, prompt, env, model);
        
        return new Response(JSON.stringify(result), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Unknown error';
        return new Response(
          JSON.stringify({ error: message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    if (url.pathname === '/api/health') {
      return new Response(JSON.stringify({ status: 'ok' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response('Not Found', { status: 404, headers: corsHeaders });
  },
};

// Detect image media type from base64 data
function detectMediaType(base64: string): string {
  // Check for common image signatures in base64
  if (base64.startsWith('/9j/') || base64.startsWith('/9J/')) {
    return 'image/jpeg';
  }
  if (base64.startsWith('iVBORw0KGgo')) {
    return 'image/png';
  }
  if (base64.startsWith('R0lGOD')) {
    return 'image/gif';
  }
  if (base64.startsWith('UklGR')) {
    return 'image/webp';
  }
  // Default to jpeg
  return 'image/jpeg';
}

async function queryProvider(
  provider: Provider,
  image: string,
  prompt: string,
  env: Env,
  model?: Model
): Promise<QueryResponse> {
  switch (provider) {
    case 'claude':
      return queryClaude(image, prompt, env.CLAUDE_API_KEY, model as ClaudeModel);
    case 'openai':
      return queryOpenAI(image, prompt, env.OPENAI_API_KEY, model as OpenAIModel);
    case 'gemini':
      return queryGemini(image, prompt, env.GEMINI_API_KEY, model as GeminiModel);
    default:
      throw new Error(`Unknown provider: ${provider}`);
  }
}

async function queryClaude(image: string, prompt: string, apiKey: string, requestedModel?: ClaudeModel): Promise<QueryResponse> {
  const model = requestedModel || 'claude-sonnet-4-5-20250929';
  const mediaType = detectMediaType(image);

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model,
      max_tokens: 4096,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: mediaType,
                data: image,
              },
            },
            {
              type: 'text',
              text: prompt,
            },
          ],
        },
      ],
    }),
  });

  if (!response.ok) {
    const error = await response.json() as { error?: { message?: string } };
    throw new Error(error.error?.message || `Claude API error: ${response.status}`);
  }

  const data = await response.json() as { content: Array<{ text: string }> };
  return {
    response: data.content[0].text,
    provider: 'claude',
    model,
  };
}

async function queryOpenAI(image: string, prompt: string, apiKey: string, requestedModel?: OpenAIModel): Promise<QueryResponse> {
  const model = requestedModel || 'gpt-5.1';
  
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      max_completion_tokens: 4096,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: {
                url: `data:image/jpeg;base64,${image}`,
              },
            },
            {
              type: 'text',
              text: prompt,
            },
          ],
        },
      ],
    }),
  });

  if (!response.ok) {
    const error = await response.json() as { error?: { message?: string } };
    throw new Error(error.error?.message || `OpenAI API error: ${response.status}`);
  }

  const data = await response.json() as { choices: Array<{ message: { content: string } }> };
  return {
    response: data.choices[0].message.content,
    provider: 'openai',
    model,
  };
}

async function queryGemini(image: string, prompt: string, apiKey: string, requestedModel?: GeminiModel): Promise<QueryResponse> {
  const model = requestedModel || 'gemini-3-pro-preview';
  const mediaType = detectMediaType(image);

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                inline_data: {
                  mime_type: mediaType,
                  data: image,
                },
              },
              {
                text: prompt,
              },
            ],
          },
        ],
      }),
    }
  );

  if (!response.ok) {
    const error = await response.json() as { error?: { message?: string } };
    throw new Error(error.error?.message || `Gemini API error: ${response.status}`);
  }

  const data = await response.json() as {
    candidates: Array<{ content: { parts: Array<{ text: string }> } }>;
  };
  return {
    response: data.candidates[0].content.parts[0].text,
    provider: 'gemini',
    model,
  };
}
