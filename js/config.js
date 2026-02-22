// js/config.js
// Fetches Supabase credentials from /api/config, then initialises the client.
// Returns null gracefully if config is unavailable.

let _client = null;
let _initPromise = null;

export async function getSupabase() {
  if (_client) return _client;
  if (_initPromise) return _initPromise;

  _initPromise = (async () => {
    try {
      const res = await fetch('/api/config');
      if (!res.ok) throw new Error(`Config ${res.status}`);
      const { url, key } = await res.json();
      if (!url || !key) throw new Error('Missing url/key');
      _client = window.supabase.createClient(url, key, {
        auth: { persistSession: false, autoRefreshToken: false },
        global: { headers: {} },
      });
      return _client;
    } catch (e) {
      console.warn('Supabase config unavailable, running in offline mode:', e.message);
      return null;
    }
  })();

  return _initPromise;
}

export const sbReady = getSupabase();
