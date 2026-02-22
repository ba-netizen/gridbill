-- ============================================================
-- GridBill — Supabase Database Schema
-- Run in: Supabase > SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ──────────────────────────────────────────────────────────
-- ENUMS
-- ──────────────────────────────────────────────────────────

CREATE TYPE commodity_type AS ENUM ('EE', 'GAS', 'WATER', 'HEAT');
CREATE TYPE customer_type  AS ENUM ('FO', 'PO');  -- fyzická / právnická osoba
CREATE TYPE customer_status AS ENUM ('active', 'warning', 'blocked', 'inactive');
CREATE TYPE risk_level     AS ENUM ('low', 'medium', 'high');
CREATE TYPE contract_status AS ENUM ('draft', 'active', 'expiring', 'expired', 'terminated');
CREATE TYPE meter_status_t  AS ENUM ('online', 'warning', 'offline');
CREATE TYPE invoice_type_t  AS ENUM ('komoditní', 'záloha', 'roční vyúčtování', 'opravný daňový doklad');
CREATE TYPE invoice_status_t AS ENUM ('draft', 'sent', 'paid', 'overdue', 'cancelled');
CREATE TYPE advance_status_t AS ENUM ('active', 'paused', 'closed');
CREATE TYPE payment_status_t AS ENUM ('future', 'pending', 'paid', 'overdue');
CREATE TYPE user_role_t      AS ENUM ('admin', 'billing_operator', 'meter_reader', 'auditor', 'viewer');
CREATE TYPE integration_status_t AS ENUM ('online', 'degraded', 'offline');

-- ──────────────────────────────────────────────────────────
-- TENANTS  (multi-tenant root)
-- ──────────────────────────────────────────────────────────

CREATE TABLE tenants (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  ico           TEXT,                          -- IČ
  vat_number    TEXT,                          -- DIČ
  address       TEXT,
  invoice_prefix TEXT DEFAULT 'FAK',
  invoice_due_days INT DEFAULT 14,
  erp_system    TEXT,
  ote_active    BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────
-- APP USERS  (extends auth.users)
-- ──────────────────────────────────────────────────────────

CREATE TABLE app_users (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name     TEXT,
  email         TEXT NOT NULL,
  role          user_role_t NOT NULL DEFAULT 'viewer',
  status        TEXT NOT NULL DEFAULT 'active',
  last_login_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_tenants (
  user_id    UUID REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id  UUID REFERENCES tenants(id)   ON DELETE CASCADE,
  PRIMARY KEY (user_id, tenant_id)
);

-- ──────────────────────────────────────────────────────────
-- CUSTOMERS
-- ──────────────────────────────────────────────────────────

CREATE TABLE customers (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id     UUID NOT NULL REFERENCES tenants(id),
  code          TEXT NOT NULL,                -- ZAK-00441
  name          TEXT NOT NULL,
  type          customer_type NOT NULL DEFAULT 'FO',
  address       TEXT,
  email         TEXT,
  phone         TEXT,
  bank_account  TEXT,                          -- IBAN CZ..
  status        customer_status NOT NULL DEFAULT 'active',
  risk_level    risk_level NOT NULL DEFAULT 'low',
  balance_czk   NUMERIC(12,2) DEFAULT 0,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, code)
);

CREATE TABLE customer_commodities (
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  commodity   commodity_type,
  PRIMARY KEY (customer_id, commodity)
);

-- ──────────────────────────────────────────────────────────
-- TARIFFS
-- ──────────────────────────────────────────────────────────

CREATE TABLE tariffs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  code            TEXT NOT NULL,              -- D25d
  name            TEXT NOT NULL,
  commodity       commodity_type NOT NULL,
  fixed_fee_czk   NUMERIC(10,2),             -- Kč/měsíc
  unit_price_czk  NUMERIC(10,4),             -- Kč/kWh nebo m³ nebo GJ
  vat_rate        NUMERIC(4,2) DEFAULT 0.21,
  valid_from      DATE NOT NULL,
  valid_to        DATE,
  eru_decision_ref TEXT,                     -- číslo cenového rozhodnutí ERÚ
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, code, valid_from)
);

-- ──────────────────────────────────────────────────────────
-- SUPPLY POINTS (OPM — Odběrné místo)
-- ──────────────────────────────────────────────────────────

CREATE TABLE supply_points (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  code        TEXT NOT NULL,              -- EAN 859182400441
  commodity   commodity_type NOT NULL,
  address     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, code)
);

-- ──────────────────────────────────────────────────────────
-- CONTRACTS
-- ──────────────────────────────────────────────────────────

CREATE TABLE contracts (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id        UUID NOT NULL REFERENCES tenants(id),
  customer_id      UUID NOT NULL REFERENCES customers(id),
  opm_id           TEXT,                    -- EAN / EIC / meter code string
  supply_point_id  UUID REFERENCES supply_points(id),
  contract_number  TEXT NOT NULL,           -- SMK-2024-0441
  commodity        commodity_type NOT NULL,
  tariff_code      TEXT,
  valid_from       DATE NOT NULL,
  valid_to         DATE,
  status           contract_status NOT NULL DEFAULT 'active',
  notes            TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, contract_number)
);

-- ──────────────────────────────────────────────────────────
-- METERS
-- ──────────────────────────────────────────────────────────

CREATE TABLE meters (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id         UUID NOT NULL REFERENCES tenants(id),
  meter_code        TEXT NOT NULL,             -- MET-EE-44101
  name              TEXT,                      -- customer name shorthand
  meter_type        TEXT,                      -- Elektroměr 3F AMI
  commodity         commodity_type NOT NULL,
  ean_eic           TEXT,                      -- EAN/EIC/VOD identifier
  current_reading   NUMERIC(14,3) DEFAULT 0,
  reading_unit      TEXT DEFAULT 'kWh',        -- kWh, m³, GJ
  meter_status      meter_status_t NOT NULL DEFAULT 'online',
  last_read_at      TIMESTAMPTZ,
  calibration_date  DATE,
  protocol          TEXT,                      -- DLMS/COSEM, NB-IoT, M-Bus…
  customer_id       UUID REFERENCES customers(id),
  supply_point_id   UUID REFERENCES supply_points(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, meter_code)
);

CREATE TABLE meter_readings (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meter_id    UUID NOT NULL REFERENCES meters(id) ON DELETE CASCADE,
  read_at     TIMESTAMPTZ NOT NULL,
  reading     NUMERIC(14,3) NOT NULL,
  consumption NUMERIC(14,3),               -- diff from previous
  read_type   TEXT DEFAULT 'automatic',    -- automatic | manual | estimated
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX ON meter_readings(meter_id, read_at DESC);

-- ──────────────────────────────────────────────────────────
-- INVOICES
-- ──────────────────────────────────────────────────────────

CREATE TABLE invoices (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id      UUID NOT NULL REFERENCES tenants(id),
  customer_id    UUID NOT NULL REFERENCES customers(id),
  contract_id    UUID REFERENCES contracts(id),
  invoice_number TEXT NOT NULL,             -- FAK-2026-04812
  invoice_type   invoice_type_t NOT NULL DEFAULT 'komoditní',
  commodity      commodity_type NOT NULL,
  period_from    DATE,
  period_to      DATE,
  amount_net     NUMERIC(12,2) NOT NULL DEFAULT 0,
  vat_rate       NUMERIC(4,2) DEFAULT 0.21,
  vat_amount     NUMERIC(12,2) GENERATED ALWAYS AS (ROUND(amount_net * vat_rate, 2)) STORED,
  total_czk      NUMERIC(12,2) GENERATED ALWAYS AS (ROUND(amount_net * (1 + vat_rate), 2)) STORED,
  status         invoice_status_t NOT NULL DEFAULT 'draft',
  issued_at      TIMESTAMPTZ DEFAULT NOW(),
  due_at         TIMESTAMPTZ,
  paid_at        TIMESTAMPTZ,
  erp_export_at  TIMESTAMPTZ,
  notes          TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, invoice_number)
);
CREATE INDEX ON invoices(tenant_id, status);
CREATE INDEX ON invoices(customer_id, issued_at DESC);

CREATE TABLE invoice_items (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id  UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity    NUMERIC(14,4),
  unit        TEXT,
  unit_price  NUMERIC(12,4),
  amount      NUMERIC(12,2) NOT NULL,
  sort_order  INT DEFAULT 0
);

-- ──────────────────────────────────────────────────────────
-- ADVANCE SCHEDULES  (Rozpis záloh)
-- ──────────────────────────────────────────────────────────

CREATE TABLE advance_schedules (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id           UUID NOT NULL REFERENCES tenants(id),
  schedule_code       TEXT NOT NULL,             -- ZAL-2026-0441
  customer_id         UUID NOT NULL REFERENCES customers(id),
  contract_id         UUID REFERENCES contracts(id),
  commodity           commodity_type NOT NULL,
  tariff_code         TEXT,
  annual_kwh          NUMERIC(12,2),
  price_per_kwh       NUMERIC(10,4),
  fixed_monthly_czk   NUMERIC(10,2) DEFAULT 0,
  amount_net          NUMERIC(10,2) NOT NULL,
  vat_rate            NUMERIC(4,2) DEFAULT 0.21,
  amount_gross        NUMERIC(10,2) GENERATED ALWAYS AS (ROUND(amount_net * (1 + vat_rate), 2)) STORED,
  period_from         DATE NOT NULL,
  period_to           DATE NOT NULL,
  status              advance_status_t NOT NULL DEFAULT 'active',
  recalc_needed       BOOLEAN DEFAULT false,
  recalc_approved_at  TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, schedule_code)
);

CREATE TABLE advance_months (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  schedule_id    UUID NOT NULL REFERENCES advance_schedules(id) ON DELETE CASCADE,
  month_number   SMALLINT NOT NULL CHECK (month_number BETWEEN 1 AND 12),
  due_date       DATE NOT NULL,
  amount_net     NUMERIC(10,2) NOT NULL,
  vat_rate       NUMERIC(4,2) DEFAULT 0.21,
  amount_gross   NUMERIC(10,2) GENERATED ALWAYS AS (ROUND(amount_net * (1 + vat_rate), 2)) STORED,
  amount_paid    NUMERIC(10,2) DEFAULT 0,
  paid_date      DATE,
  payment_status payment_status_t NOT NULL DEFAULT 'future',
  invoice_id     UUID REFERENCES invoices(id),
  UNIQUE (schedule_id, month_number)
);

-- ──────────────────────────────────────────────────────────
-- BANK PAYMENTS  (bankovní výpis)
-- ──────────────────────────────────────────────────────────

CREATE TABLE bank_payments (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id           UUID NOT NULL REFERENCES tenants(id),
  payment_code        TEXT NOT NULL,            -- PLT-001
  variable_symbol     TEXT,
  constant_symbol     TEXT,
  specific_symbol     TEXT,
  amount_czk          NUMERIC(12,2) NOT NULL,
  sender_name         TEXT,
  sender_account      TEXT,
  received_at         TIMESTAMPTZ NOT NULL,
  bank_format         TEXT,                     -- MT940, CAMT.053, ABO
  matched             BOOLEAN DEFAULT false,
  matched_invoice_id  UUID REFERENCES invoices(id),
  matched_at          TIMESTAMPTZ,
  notes               TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, payment_code)
);
CREATE INDEX ON bank_payments(tenant_id, matched, received_at DESC);

-- ──────────────────────────────────────────────────────────
-- BUILDINGS  (RÚNT – rozúčtování tepla)
-- ──────────────────────────────────────────────────────────

CREATE TABLE buildings (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id             UUID NOT NULL REFERENCES tenants(id),
  name                  TEXT NOT NULL,
  year                  SMALLINT NOT NULL,
  unit_count            INT DEFAULT 0,
  total_cost_czk        NUMERIC(12,2) DEFAULT 0,
  deliverer_customer_id UUID REFERENCES customers(id),
  status                TEXT DEFAULT 'open',     -- open | closed
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tenant_id, name, year)
);

CREATE TABLE building_units (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  building_id   UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  unit_name     TEXT NOT NULL,               -- Byt 1/2 (52 m²)
  ean           TEXT,                        -- KALORIMETR K-0101
  cost_fixed    NUMERIC(10,2) DEFAULT 0,     -- základní složka
  cost_variable NUMERIC(10,2) DEFAULT 0,     -- spotřební složka
  cost_total    NUMERIC(10,2) GENERATED ALWAYS AS (cost_fixed + cost_variable) STORED
);

-- ──────────────────────────────────────────────────────────
-- INTEGRATIONS  (external systems)
-- ──────────────────────────────────────────────────────────

CREATE TABLE integrations (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id),
  icon        TEXT,
  name        TEXT NOT NULL,
  description TEXT,
  status      integration_status_t DEFAULT 'online',
  last_sync   TIMESTAMPTZ,
  error_msg   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────
-- ACTIVITY LOG
-- ──────────────────────────────────────────────────────────

CREATE TABLE activity_log (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id  UUID REFERENCES tenants(id),
  user_id    UUID REFERENCES app_users(id),
  icon       TEXT,
  title      TEXT NOT NULL,
  detail     TEXT,
  entity     TEXT,              -- invoices, customers, etc.
  entity_id  UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX ON activity_log(tenant_id, created_at DESC);

-- ──────────────────────────────────────────────────────────
-- VIEWS
-- ──────────────────────────────────────────────────────────

-- Dashboard KPIs
CREATE OR REPLACE VIEW dashboard_kpis AS
SELECT
  (SELECT COUNT(*) FROM customers WHERE status = 'active')                    AS active_customers,
  (SELECT COUNT(*) FROM contracts WHERE status = 'active')                    AS active_contracts,
  (SELECT COALESCE(SUM(total_czk),0) / 1e6 FROM invoices
   WHERE EXTRACT(YEAR FROM issued_at) = EXTRACT(YEAR FROM NOW()))             AS invoiced_ytd_m,
  (SELECT COALESCE(SUM(amount_czk),0) / 1e6 FROM bank_payments
   WHERE EXTRACT(YEAR FROM received_at) = EXTRACT(YEAR FROM NOW()))           AS collected_ytd_m,
  (SELECT COUNT(*) FROM invoices WHERE status = 'overdue')                    AS overdue_count,
  (SELECT COALESCE(SUM(total_czk),0) / 1e6 FROM invoices WHERE status = 'overdue') AS overdue_czk_m,
  (SELECT COUNT(*) FROM bank_payments WHERE matched = false)                  AS unmatched_payments;

-- Invoice stats for the invoices screen KPIs
CREATE OR REPLACE VIEW invoice_stats AS
SELECT
  COUNT(*)                                     AS total,
  COUNT(*) FILTER (WHERE status = 'paid')      AS paid,
  COUNT(*) FILTER (WHERE status = 'sent')      AS sent,
  COUNT(*) FILTER (WHERE status = 'overdue')   AS overdue,
  COALESCE(SUM(total_czk) FILTER (WHERE status = 'overdue'), 0) / 1e6 AS overdue_czk_m
FROM invoices;

-- ──────────────────────────────────────────────────────────
-- TRIGGERS — updated_at
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customers_updated_at BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ──────────────────────────────────────────────────────────
-- TRIGGER — activity log on invoice status change
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION log_invoice_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status <> OLD.status THEN
    INSERT INTO activity_log (tenant_id, icon, title, detail, entity, entity_id)
    VALUES (
      NEW.tenant_id,
      CASE NEW.status
        WHEN 'paid'    THEN '✅'
        WHEN 'overdue' THEN '🔴'
        WHEN 'sent'    THEN '📧'
        ELSE '📄'
      END,
      'Faktura ' || NEW.invoice_number || ' – stav: ' || NEW.status,
      (SELECT name FROM customers WHERE id = NEW.customer_id),
      'invoices',
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER invoice_status_log AFTER UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION log_invoice_status_change();
