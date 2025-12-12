export interface Env {
  CLAUDE_API_KEY: string;
  OPENAI_API_KEY: string;
  GEMINI_API_KEY: string;
  BRAVE_SEARCH_API_KEY: string;
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
  searchEnabled?: boolean; // default: true
  searchResultsPerQuery?: number; // default: 5, range: 1-10
}

interface QueryResponse {
  response: string;
  provider: string;
  model: string;
  searchQueries?: string[]; // queries that were searched (for transparency)
  searchPerformed?: boolean; // whether search was actually done
}

interface SearchResult {
  query: string;
  title: string;
  snippet: string;
  url: string;
}

interface TranscribeRequest {
  audio: string; // base64 encoded audio
  format?: 'webm' | 'mp4' | 'wav' | 'm4a';
}

interface TranscribeResponse {
  text: string;
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
        const searchEnabled = body.searchEnabled !== false; // default: true
        const searchResultsPerQuery = Math.min(10, Math.max(1, body.searchResultsPerQuery ?? 5));

        if (!image || !prompt || !provider) {
          return new Response(
            JSON.stringify({ error: 'Missing required fields: image, prompt, provider' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        let enhancedPrompt = prompt;
        let searchQueries: string[] = [];
        let searchPerformed = false;

        // Perform web search if enabled and API key is available
        if (searchEnabled && env.BRAVE_SEARCH_API_KEY) {
          try {
            // Extract search queries using the same provider/model
            searchQueries = await extractSearchQueries(image, prompt, provider, model, env);

            if (searchQueries.length > 0) {
              // Perform searches in parallel
              const searchResults = await searchBrave(searchQueries, searchResultsPerQuery, env.BRAVE_SEARCH_API_KEY);

              if (searchResults.length > 0) {
                // Build enhanced prompt with search context
                const searchContext = buildSearchContext(searchResults);
                enhancedPrompt = `${prompt}\n\n${searchContext}`;
                searchPerformed = true;
              }
            }
          } catch (searchError) {
            // Log but continue without search on error (graceful degradation)
            console.error('Search failed, continuing without search:', searchError);
          }
        }

        const result = await queryProvider(provider, image, enhancedPrompt, env, model);

        return new Response(JSON.stringify({
          ...result,
          searchQueries: searchQueries.length > 0 ? searchQueries : undefined,
          searchPerformed,
        }), {
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

    if (url.pathname === '/api/transcribe' && request.method === 'POST') {
      try {
        const body: TranscribeRequest = await request.json();
        const { audio, format = 'webm' } = body;

        if (!audio) {
          return new Response(
            JSON.stringify({ error: 'Missing required field: audio' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        const result = await transcribeAudio(audio, format, env.OPENAI_API_KEY);

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

async function transcribeAudio(
  base64Audio: string,
  format: string,
  apiKey: string
): Promise<TranscribeResponse> {
  // Convert base64 to binary
  const binaryString = atob(base64Audio);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }

  // Map format to MIME type
  const mimeTypes: Record<string, string> = {
    webm: 'audio/webm',
    mp4: 'audio/mp4',
    m4a: 'audio/m4a',
    wav: 'audio/wav',
  };
  const mimeType = mimeTypes[format] || 'audio/webm';

  // Create form data with audio file
  const formData = new FormData();
  const blob = new Blob([bytes], { type: mimeType });
  formData.append('file', blob, `audio.${format}`);
  formData.append('model', 'whisper-1');

  const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
    },
    body: formData,
  });

  if (!response.ok) {
    const error = await response.json() as { error?: { message?: string } };
    throw new Error(error.error?.message || `Whisper API error: ${response.status}`);
  }

  const data = await response.json() as { text: string };
  return { text: data.text };
}

// Search Query Extraction - uses the same provider/model to generate search queries
async function extractSearchQueries(
  image: string,
  prompt: string,
  provider: Provider,
  model: Model | undefined,
  env: Env
): Promise<string[]> {
  const extractionPrompt = `Given this image and the user's question, generate 1-3 web search queries that would help provide a more informed answer. Return ONLY a JSON array of search query strings, nothing else.

User's question: ${prompt}

Example response format: ["search query 1", "search query 2"]`;

  try {
    const result = await queryProviderText(provider, image, extractionPrompt, env, model);

    // Parse the JSON array from the response
    const jsonMatch = result.match(/\[[\s\S]*?\]/);
    if (jsonMatch) {
      const queries = JSON.parse(jsonMatch[0]) as string[];
      // Limit to 3 queries max
      return queries.slice(0, 3).filter(q => typeof q === 'string' && q.trim().length > 0);
    }
  } catch (error) {
    console.error('Failed to extract search queries:', error);
  }

  return [];
}

// Query provider and return just the text response (for extraction calls)
async function queryProviderText(
  provider: Provider,
  image: string,
  prompt: string,
  env: Env,
  model?: Model
): Promise<string> {
  const result = await queryProvider(provider, image, prompt, env, model);
  return result.response;
}

// Brave Search API integration
async function searchBrave(
  queries: string[],
  resultsPerQuery: number,
  apiKey: string
): Promise<SearchResult[]> {
  const allResults: SearchResult[] = [];

  // Run searches in parallel
  const searchPromises = queries.map(async (query) => {
    try {
      const response = await fetch(
        `https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(query)}&count=${resultsPerQuery}`,
        {
          headers: {
            'X-Subscription-Token': apiKey,
            'Accept': 'application/json',
          },
        }
      );

      if (!response.ok) {
        console.error(`Brave search failed for "${query}": ${response.status}`);
        return [];
      }

      const data = await response.json() as {
        web?: {
          results?: Array<{
            title: string;
            url: string;
            description: string;
          }>;
        };
      };

      return (data.web?.results || []).map((result) => ({
        query,
        title: result.title,
        snippet: result.description,
        url: result.url,
      }));
    } catch (error) {
      console.error(`Brave search error for "${query}":`, error);
      return [];
    }
  });

  const resultsArrays = await Promise.all(searchPromises);
  for (const results of resultsArrays) {
    allResults.push(...results);
  }

  return allResults;
}

// Build search context to inject into the prompt
function buildSearchContext(results: SearchResult[]): string {
  if (results.length === 0) return '';

  // Group results by query
  const byQuery = new Map<string, SearchResult[]>();
  for (const result of results) {
    const existing = byQuery.get(result.query) || [];
    existing.push(result);
    byQuery.set(result.query, existing);
  }

  let context = '---\n**Web Search Context:**\n\n';

  for (const [query, queryResults] of byQuery) {
    context += `Search: "${query}"\n`;
    for (const result of queryResults) {
      context += `- ${result.title}: ${result.snippet} (${result.url})\n`;
    }
    context += '\n';
  }

  context += '---\nPlease answer the question using both the image and the search context above.';

  return context;
}
