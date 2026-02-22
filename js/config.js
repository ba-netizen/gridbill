// js/config.js
// Fetches Supabase credentials from /api/config, then initialises the client.
// Exports a promise that resolves to the ready supabase client.

let _client = null;

export async function getSupabase() {
  if (_client) return _client;

  // Fetch public credentials from serverless endpoint
  const res = await fetch('/api/config');
  if (!res.ok) {
    throw new Error(`Failed to load app config: ${res.status}`);
  }
  const { url, key } = await res.json();

  // supabase-js v2 loaded via CDN in index.html
  _client = window.supabase.createClient(url, key, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  });
  return _client;
}

// Convenience: resolved once on first call, used everywhere
export const sbReady = getSupabase();
