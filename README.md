# GridBill — Distributor Billing Platform

Multi-commodity utility billing system for Czech energy distributors.  
Electricity · Gas · Water · Heat (RÚNT)

---

## Quick deploy (5 minutes)

### 1. Create Supabase project

1. Go to [supabase.com](https://supabase.com) → **New project**
2. Choose a region close to Czech Republic (e.g. Frankfurt)
3. Save the **Project URL** and **anon public key** from:  
   `Project Settings → API`

### 2. Set up the database

Open **Supabase → SQL Editor** and run in order:

```
supabase/00_schema.sql   ← tables, views, triggers
supabase/01_rls.sql      ← row level security policies
supabase/02_seed.sql     ← demo data (ČEZ Distribuce tenant + all sample records)
```

### 3. Create first user

In **Supabase → Authentication → Users** create a user, then run:

```sql
INSERT INTO app_users (id, full_name, email, role, status)
VALUES (
  '<paste-user-uuid-from-auth>',
  'Jan Novák',
  'admin@energo.cz',
  'admin',
  'active'
);

INSERT INTO user_tenants (user_id, tenant_id)
VALUES (
  '<paste-user-uuid>',
  '11111111-0000-0000-0000-000000000001'  -- ČEZ Distribuce from seed
);
```

### 4. Deploy to Vercel

**Via GitHub (recommended):**
1. Push this repo to GitHub
2. [vercel.com](https://vercel.com) → **Add New Project** → import your repo
3. Set environment variables:

| Variable | Value |
|---|---|
| `SUPABASE_URL` | `https://your-project.supabase.co` |
| `SUPABASE_ANON_KEY` | `eyJhbGci...` (anon key from Supabase) |
| `APP_ENV` | `production` |

4. Click **Deploy** — done ✓

**Via CLI:**
```bash
npm i -g vercel
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
vercel --prod
```

### 5. Local development

```bash
cp .env.example .env.local
# fill in SUPABASE_URL and SUPABASE_ANON_KEY
npx serve . -p 3000
```

---

## Project structure

```
gridbill/
├── index.html          ← SPA shell (CSS + HTML, no inline JS)
├── js/
│   ├── config.js       ← Supabase client init (fetches creds from /api/config)
│   ├── api.js          ← All database queries
│   └── app.js          ← UI logic, screen rendering, navigation
├── api/
│   └── config.js       ← Vercel serverless: exposes public Supabase creds
├── supabase/
│   ├── 00_schema.sql   ← Database tables, views, triggers
│   ├── 01_rls.sql      ← Row Level Security (tenant isolation)
│   └── 02_seed.sql     ← Demo data
├── vercel.json         ← Routing, headers, caching
├── package.json
├── .env.example
└── README.md
```

---

## Database overview

| Table | Description |
|---|---|
| `tenants` | Multi-tenant root — one per distributor |
| `app_users` | Users (extends Supabase auth.users) |
| `customers` | Zákazníci — FO/PO |
| `customer_commodities` | Which commodities each customer uses |
| `contracts` | Smlouvy with OPM/EAN |
| `supply_points` | Odběrná místa |
| `meters` | Měřidla (AMI/AMR) |
| `meter_readings` | Odečty — time series |
| `tariffs` | Distribuční sazby ERÚ |
| `invoices` | Faktury with generated VAT columns |
| `invoice_items` | Položky faktury |
| `advance_schedules` | Zálohové kalendáře |
| `advance_months` | Měsíční zálohy (12 rows per schedule) |
| `bank_payments` | Bankovní výpis (MT940/CAMT/ABO) |
| `buildings` | RÚNT — budovy pro rozúčtování tepla |
| `building_units` | Bytové jednotky s kalorimetry |
| `integrations` | OTE, SAP, M-Bus, SendGrid status |
| `activity_log` | Audit log |

**Views:** `dashboard_kpis`, `invoice_stats`

---

## User roles

| Role | Access |
|---|---|
| `admin` | Full access, user management, tariff import |
| `billing_operator` | Customers, contracts, invoices, payments, advances |
| `meter_reader` | Meters and readings only |
| `auditor` | Read-only across all data |
| `viewer` | Read-only, own tenant only |

---

## Adding a second tenant

```sql
INSERT INTO tenants (name, ico, invoice_prefix, ote_active)
VALUES ('E.ON Distribuce, a.s.', '28085400', 'EON', true);

-- Then assign users via user_tenants table
```

---

## Architecture notes

- **No build step** — vanilla ES modules loaded directly by browser
- **Security** — Supabase anon key is public; all access controlled by RLS policies  
- **Serverless config** — `/api/config.js` injects Supabase credentials at runtime  
- **Multi-tenant** — every table has `tenant_id`; RLS enforces isolation automatically
- **Offline-tolerant** — screens show loading spinners and graceful error states
