// api/config.js
// Vercel serverless function – returns public Supabase credentials to the frontend.
// The anon key is safe to expose; security is enforced by Supabase RLS policies.

export default function handler(req, res) {
  // Only GET
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const url  = process.env.SUPABASE_URL;
  const key  = process.env.SUPABASE_ANON_KEY;
  const env  = process.env.APP_ENV || 'production';

  if (!url || !key) {
    return res.status(500).json({
      error: 'Supabase credentials not configured',
      hint: 'Set SUPABASE_URL and SUPABASE_ANON_KEY in Vercel environment variables',
    });
  }

  // Cache for 5 minutes on CDN – these values rarely change
  res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=60');
  res.setHeader('Content-Type', 'application/json');

  return res.status(200).json({ url, key, env });
}
