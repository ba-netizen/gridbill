-- ============================================================
-- GridBill — Seed Data
-- Run AFTER 00_schema.sql and 01_rls.sql
-- Creates demo tenant + all sample data from prototype
-- ============================================================

-- NOTE: Replace UUID placeholders after running if needed.
-- Using fixed UUIDs so foreign keys resolve correctly.

DO $$
DECLARE
  t_id  UUID := '11111111-0000-0000-0000-000000000001';  -- tenant: ČEZ Distribuce
  c1 UUID := '22222222-0000-0000-0001-000000000001';  -- Karel Dvořák
  c2 UUID := '22222222-0000-0000-0001-000000000002';  -- MASO a.s.
  c3 UUID := '22222222-0000-0000-0001-000000000003';  -- Jana Procházková
  c4 UUID := '22222222-0000-0000-0001-000000000004';  -- BUILDING.cz s.r.o.
  c5 UUID := '22222222-0000-0000-0001-000000000005';  -- Petr Novotný
  c6 UUID := '22222222-0000-0000-0001-000000000006';  -- SVJ Horní 12
  c7 UUID := '22222222-0000-0000-0001-000000000007';  -- Restaurace U Kohouta
  c8 UUID := '22222222-0000-0000-0001-000000000008';  -- Marie Nováková
BEGIN

-- ── TENANT ──────────────────────────────────────────────────────
INSERT INTO tenants (id, name, ico, vat_number, address, invoice_prefix, invoice_due_days, erp_system, ote_active)
VALUES (t_id, 'ČEZ Distribuce, a.s.', '24729035', 'CZ24729035',
        'Duhová 2/1444, 140 53 Praha 4', 'FAK', 14, 'SAP', true)
ON CONFLICT DO NOTHING;

-- ── CUSTOMERS ───────────────────────────────────────────────────
INSERT INTO customers (id, tenant_id, code, name, type, address, email, phone, bank_account, status, risk_level, balance_czk) VALUES
  (c1, t_id, 'ZAK-00441', 'Karel Dvořák',           'FO', 'Jiráskova 14, Praha 2',       'karel.dvorak@email.cz',   '+420 602 111 001', 'CZ65 0800 0000 0001 2345 6789', 'active',  'low',    2480),
  (c2, t_id, 'ZAK-00892', 'MASO a.s.',              'PO', 'Průmyslová 44, Brno',         'info@maso.cz',            '+420 545 222 002', 'CZ12 0100 0000 0092 8800 0001', 'active',  'high', -14800),
  (c3, t_id, 'ZAK-01204', 'Jana Procházková',        'FO', 'Tylova 8, Ostrava',           'jana.prochaz@email.cz',   '+420 596 333 003', 'CZ44 0300 0000 0001 2204 5678', 'active',  'low',      0),
  (c4, t_id, 'ZAK-01540', 'BUILDING.cz s.r.o.',     'PO', 'Nová 22, Plzeň',              'billing@building.cz',     '+420 377 444 004', 'CZ81 0600 0000 0054 0100 0001', 'warning', 'medium', -4200),
  (c5, t_id, 'ZAK-02008', 'Petr Novotný',            'FO', 'K Lesu 3, Olomouc',          'p.novotny@email.cz',      '+420 585 555 005', 'CZ22 0800 0000 0012 3456 7891', 'active',  'low',     800),
  (c6, t_id, 'ZAK-02344', 'SVJ Horní 12',            'PO', 'Horní 12, Liberec',          'svj.horni12@email.cz',    '+420 485 666 006', 'CZ55 0100 0000 0023 4400 0012', 'active',  'low',    5120),
  (c7, t_id, 'ZAK-02810', 'Restaurace U Kohouta',    'PO', 'Náměstí 1, Pardubice',       'kohouta@restaurace.cz',   '+420 466 777 007', 'CZ88 0800 0000 0028 1000 0001', 'blocked', 'high', -28400),
  (c8, t_id, 'ZAK-03102', 'Marie Nováková',          'FO', 'Lipová 5, České Budějovice', 'marie.novakova@email.cz', '+420 387 888 008', 'CZ11 0800 0000 0031 0200 0001', 'active',  'low',      0)
ON CONFLICT DO NOTHING;

-- ── CUSTOMER COMMODITIES ────────────────────────────────────────
INSERT INTO customer_commodities (customer_id, commodity) VALUES
  (c1, 'EE'), (c1, 'GAS'),
  (c2, 'EE'), (c2, 'GAS'), (c2, 'HEAT'),
  (c3, 'EE'), (c3, 'WATER'),
  (c4, 'EE'), (c4, 'WATER'), (c4, 'HEAT'),
  (c5, 'GAS'),
  (c6, 'HEAT'), (c6, 'WATER'),
  (c7, 'EE'), (c7, 'GAS'),
  (c8, 'EE')
ON CONFLICT DO NOTHING;

-- ── TARIFFS ─────────────────────────────────────────────────────
INSERT INTO tariffs (tenant_id, code, name, commodity, fixed_fee_czk, unit_price_czk, vat_rate, valid_from) VALUES
  (t_id, 'D01d',   'Jednotarifový – domácnost',         'EE',    213, 1.84, 0.21, '2026-01-01'),
  (t_id, 'D25d',   'Dvoutarifový – akumulace',          'EE',    384, 1.44, 0.21, '2026-01-01'),
  (t_id, 'C35d',   'Malý podnik – dvoutarifový',        'EE',   2200, 1.62, 0.21, '2026-01-01'),
  (t_id, 'D3',     'Domácnost – maloodběr',             'GAS',   104, 1.12, 0.21, '2026-01-01'),
  (t_id, 'VD-DN20','Vodoměr DN20 – domácnost',          'WATER',  15, 92.40, 0.15, '2026-01-01'),
  (t_id, 'VD-DN32','Vodoměr DN32 – firma',              'WATER',  40, 88.20, 0.15, '2026-01-01'),
  (t_id, 'CZT-A',  'Teplo – bytový dům (základ)',       'HEAT', 1200, 580, 0.15, '2026-01-01'),
  (t_id, 'CZT-B',  'Teplo – bytový dům (tarif B)',      'HEAT', 1500, 640, 0.15, '2026-01-01')
ON CONFLICT DO NOTHING;

-- ── CONTRACTS ───────────────────────────────────────────────────
INSERT INTO contracts (tenant_id, customer_id, opm_id, contract_number, commodity, tariff_code, valid_from, valid_to, status) VALUES
  (t_id, c1, 'EAN 859182400441', 'SMK-2024-0441', 'EE',   'D25d',   '2024-03-01', '2027-02-28', 'active'),
  (t_id, c2, 'EAN 859182400892', 'SMK-2024-0892', 'EE',   'C35d',   '2024-06-15', '2026-06-14', 'active'),
  (t_id, c3, 'EIC Z12345678',    'SMK-2023-1204', 'GAS',  'D3',     '2023-01-01', '2025-12-31', 'expiring'),
  (t_id, c4, 'KALORIMETR K-2201','SMK-2025-1540', 'HEAT', 'CZT-B',  '2025-04-01', '2028-03-31', 'active'),
  (t_id, c5, 'VOD-884-002008',   'SMK-2022-2008', 'WATER','VD-DN32','2022-08-12', '2026-08-11', 'active'),
  (t_id, c6, 'KALORIMETR K-9901','SMK-2025-2344', 'HEAT', 'CZT-A',  '2025-01-01', '2027-12-31', 'active'),
  (t_id, c7, 'EAN 859182400230', 'SMK-2021-2810', 'EE',   'C35d',   '2021-03-01', '2024-02-29', 'expired'),
  (t_id, c8, 'EAN 859182403102', 'SMK-2023-3102', 'EE',   'D01d',   '2023-07-01', '2026-06-30', 'active')
ON CONFLICT DO NOTHING;

-- ── METERS ──────────────────────────────────────────────────────
INSERT INTO meters (tenant_id, customer_id, meter_code, name, meter_type, commodity, ean_eic, current_reading, reading_unit, meter_status, last_read_at, calibration_date, protocol) VALUES
  (t_id, c1, 'MET-EE-44101', 'Dvořák Karel',          'Elektroměr 3F',      'EE',    'EAN 859182400441',  14284,   'kWh', 'online',  NOW() - INTERVAL '1 hour',  '2030-04-01', 'DLMS/COSEM · AMI'),
  (t_id, c2, 'MET-EE-44102', 'MASO a.s.',             'Elektroměr 3F AMI',  'EE',    'EAN 859182400892',  284128,  'kWh', 'online',  NOW() - INTERVAL '1 hour',  '2031-08-01', 'DLMS/COSEM · AMI'),
  (t_id, c3, 'MET-GAS-8801', 'Procházková J.',         'Plynoměr G6',        'GAS',   'EIC Z12345678',     8421,    'm³',  'warning', NOW() - INTERVAL '48 hours','2027-03-01', 'NB-IoT · denní data'),
  (t_id, c5, 'MET-WAT-2201', 'Novotný P.',             'Vodoměr DN20',       'WATER', 'VOD-884-002008',    342,     'm³',  'online',  NOW() - INTERVAL '10 days', '2026-10-01', 'Wireless M-Bus 868MHz'),
  (t_id, c6, 'MET-HEAT-9901','SVJ Horní 12',           'Kalorimetr',         'HEAT',  'KALORIMETR K-9901', 124.8,   'GJ',  'online',  NOW() - INTERVAL '2 hours', '2029-01-01', 'M-Bus wired'),
  (t_id, c7, 'MET-EE-44230', 'Restaurace U Kohouta',   'Elektroměr 1F',      'EE',    'EAN 859182400230',  42881,   'kWh', 'offline', NOW() - INTERVAL '5 days',  '2028-06-01', 'DLMS/COSEM'),
  (t_id, c4, 'MET-GAS-8802', 'BUILDING.cz s.r.o.',     'Plynoměr G10',       'GAS',   'EIC Z98765432',     14220,   'm³',  'online',  NOW() - INTERVAL '2 hours', '2028-11-01', 'NB-IoT · denní data'),
  (t_id, c8, 'MET-WAT-2205', 'Marie Nováková',          'Vodoměr DN15',       'WATER', 'VOD-881-003102',    185,     'm³',  'online',  NOW() - INTERVAL '12 days', '2026-08-01', 'Wireless M-Bus 868MHz')
ON CONFLICT DO NOTHING;

-- ── INVOICES ────────────────────────────────────────────────────
INSERT INTO invoices (tenant_id, customer_id, invoice_number, invoice_type, commodity, period_from, period_to, amount_net, vat_rate, status, issued_at, due_at) VALUES
  (t_id, c1, 'FAK-2026-04812', 'komoditní',        'EE',   '2026-01-01', '2026-01-31',  3538.84, 0.21, 'paid',    '2026-02-01', '2026-02-15'),
  (t_id, c2, 'FAK-2026-04811', 'komoditní',        'EE',   '2026-01-01', '2026-01-31', 23504.13, 0.21, 'overdue', '2026-02-01', '2026-02-15'),
  (t_id, c3, 'FAK-2026-04810', 'komoditní',        'GAS',  '2026-01-01', '2026-01-31',  2578.51, 0.21, 'sent',    '2026-02-01', '2026-02-15'),
  (t_id, c4, 'FAK-2026-04809', 'záloha',           'HEAT', '2026-02-01', '2026-02-28',  7339.13, 0.15, 'paid',    '2026-02-01', '2026-02-15'),
  (t_id, c6, 'FAK-2026-04808', 'komoditní',        'WATER','2026-01-01', '2026-01-31',  2504.35, 0.15, 'sent',    '2026-02-01', '2026-02-15'),
  (t_id, c7, 'FAK-2026-04807', 'komoditní',        'EE',   '2026-01-01', '2026-01-31', 10280.99, 0.21, 'overdue', '2026-02-01', '2026-02-15'),
  (t_id, c8, 'FAK-2026-04806', 'roční vyúčtování', 'EE',   '2025-10-01', '2025-12-31',  3008.26, 0.21, 'paid',    '2026-01-15', '2026-01-29')
ON CONFLICT DO NOTHING;

-- ── INVOICE ITEMS (for FAK-2026-04812) ─────────────────────────
INSERT INTO invoice_items (invoice_id, description, quantity, unit, unit_price, amount, sort_order)
SELECT id, 'Spotřeba elektřiny 1 284 kWh × 1.84 Kč', 1284, 'kWh', 1.84, ROUND(1284 * 1.84, 2), 1
FROM invoices WHERE invoice_number = 'FAK-2026-04812'
ON CONFLICT DO NOTHING;

INSERT INTO invoice_items (invoice_id, description, quantity, unit, unit_price, amount, sort_order)
SELECT id, 'Pevná platba za distribuci', 1, 'měsíc', 213, 213, 2
FROM invoices WHERE invoice_number = 'FAK-2026-04812'
ON CONFLICT DO NOTHING;

-- ── ADVANCE SCHEDULES ───────────────────────────────────────────
INSERT INTO advance_schedules
  (tenant_id, schedule_code, customer_id, commodity, tariff_code, annual_kwh, price_per_kwh, fixed_monthly_czk, amount_net, vat_rate, period_from, period_to, status, recalc_needed)
VALUES
  (t_id, 'ZAL-2026-0441', c1, 'EE',   'D25d', 4560, 1.84, 213,  912,  0.21, '2026-01-01', '2026-12-31', 'active', false),
  (t_id, 'ZAL-2026-0892', c2, 'EE',   'C35d', 180000, 1.62, 2200, 24000, 0.21, '2026-01-01', '2026-12-31', 'active', true),
  (t_id, 'ZAL-2026-1204', c3, 'GAS',  'D3',   18000, 1.12, 104,  1680, 0.21, '2026-01-01', '2026-12-31', 'active', false),
  (t_id, 'ZAL-2026-2344', c6, 'HEAT', 'CZT-A',0,     0,    0,    8440, 0.15, '2026-01-01', '2026-12-31', 'active', false)
ON CONFLICT DO NOTHING;

-- ── ADVANCE MONTHS (for ZAL-2026-0441) ──────────────────────────
DO $$
DECLARE
  sch_id UUID;
  i INT;
  d DATE := '2026-01-15';
  pstatus payment_status_t;
BEGIN
  SELECT id INTO sch_id FROM advance_schedules WHERE schedule_code = 'ZAL-2026-0441';
  FOR i IN 1..12 LOOP
    pstatus := CASE
      WHEN i < EXTRACT(MONTH FROM NOW()) THEN 'paid'
      WHEN i = EXTRACT(MONTH FROM NOW()) THEN 'pending'
      ELSE 'future'
    END;
    INSERT INTO advance_months (schedule_id, month_number, due_date, amount_net, vat_rate, amount_paid, paid_date, payment_status)
    VALUES (
      sch_id, i, d + (i-1) * INTERVAL '1 month',
      912, 0.21,
      CASE WHEN pstatus = 'paid' THEN 1103.52 ELSE 0 END,
      CASE WHEN pstatus = 'paid' THEN (d + (i-1) * INTERVAL '1 month')::DATE + 2 ELSE NULL END,
      pstatus
    ) ON CONFLICT DO NOTHING;
  END LOOP;
END $$;

-- ── BANK PAYMENTS ───────────────────────────────────────────────
INSERT INTO bank_payments (tenant_id, payment_code, variable_symbol, amount_czk, sender_name, sender_account, received_at, matched) VALUES
  (t_id, 'PLT-001', '202600441', 4280,  'Karel Dvořák',           'CZ65 0800 ....4589', NOW() - INTERVAL '2 days', true),
  (t_id, 'PLT-002', '202600892', 28440, 'MASO a.s.',              'CZ12 0100 ....8822', NOW() - INTERVAL '1 day',  false),
  (t_id, 'PLT-003', '',          3120,  'Procházková Jana',        'CZ44 0300 ....1122', NOW() - INTERVAL '1 day',  false),
  (t_id, 'PLT-004', '202601204', 3120,  'Jana Procházková',        'CZ44 0300 ....1122', NOW() - INTERVAL '3 days', true),
  (t_id, 'PLT-005', '',          880,   '—',                       'CZ99 0800 ....4421', NOW() - INTERVAL '1 day',  false)
ON CONFLICT DO NOTHING;

-- Update PLT-001 with matched invoice
UPDATE bank_payments b
SET matched_invoice_id = i.id, matched_at = NOW() - INTERVAL '2 days'
FROM invoices i
WHERE i.invoice_number = 'FAK-2026-04812'
  AND b.payment_code = 'PLT-001'
  AND b.matched_invoice_id IS NULL;

-- ── BUILDINGS (RÚNT) ─────────────────────────────────────────────
DO $$
DECLARE
  b1 UUID; b2 UUID;
BEGIN
  INSERT INTO buildings (tenant_id, name, year, unit_count, total_cost_czk, deliverer_customer_id, status)
  VALUES
    ('11111111-0000-0000-0000-000000000001', 'Horní 12, Liberec', 2025, 24, 248440, '22222222-0000-0000-0001-000000000006', 'open'),
    ('11111111-0000-0000-0000-000000000001', 'Nábřežní 8, Praha', 2025, 12, 124800, '22222222-0000-0000-0001-000000000004', 'closed')
  ON CONFLICT DO NOTHING
  RETURNING id INTO b1;

  SELECT id INTO b1 FROM buildings WHERE name = 'Horní 12, Liberec' AND year = 2025;
  SELECT id INTO b2 FROM buildings WHERE name = 'Nábřežní 8, Praha' AND year = 2025;

  INSERT INTO building_units (building_id, unit_name, ean, cost_fixed, cost_variable) VALUES
    (b1, 'Byt 1/2 (52 m²)',       'KALORIMETR K-0101', 2844, 7122),
    (b1, 'Byt 2/4 (78 m²)',       'KALORIMETR K-0102', 4266, 8440),
    (b1, 'Byt 3/6 (45 m²)',       'KALORIMETR K-0103', 2466, 5880),
    (b1, 'Nebytový – prodejna',   'KALORIMETR K-0104', 3622, 4200),
    (b2, 'Byt 1/1 (64 m²)',       'KALORIMETR K-0201', 3480, 6800),
    (b2, 'Byt 1/3 (48 m²)',       'KALORIMETR K-0202', 2610, 4900)
  ON CONFLICT DO NOTHING;
END $$;

-- ── INTEGRATIONS ────────────────────────────────────────────────
INSERT INTO integrations (tenant_id, icon, name, description, status, last_sync) VALUES
  (t_id, '⚡', 'OTE Datahub',    'Registrace OPM, 15min data, fakturační dávky', 'online',    NOW() - INTERVAL '5 minutes'),
  (t_id, '🏦', 'ČSOB Bank API',  'Bankovní výpisy MT940, příkazy k úhradě',      'online',    NOW() - INTERVAL '1 hour'),
  (t_id, '🏭', 'SAP ERP',        'Agregovaný export faktur a DPH',               'online',    NOW() - INTERVAL '30 minutes'),
  (t_id, '📡', 'AMI Head-End',   '15min data z 8 440 elektroměrů',              'degraded',  NOW() - INTERVAL '2 hours'),
  (t_id, '💧', 'M-Bus Gateway',  'Kalorimetry a vodoměry',                       'online',    NOW() - INTERVAL '1 hour'),
  (t_id, '📧', 'SendGrid',       'E-mailová komunikace se zákazníky',            'online',    NOW() - INTERVAL '10 minutes')
ON CONFLICT DO NOTHING;

-- ── ACTIVITY LOG ────────────────────────────────────────────────
INSERT INTO activity_log (tenant_id, icon, title, detail, entity, created_at) VALUES
  (t_id, '✅', 'Faktura FAK-2026-04812 zaplacena',      'Karel Dvořák · 4 280 Kč',                   'invoices',  NOW() - INTERVAL '2 hours'),
  (t_id, '🔴', 'Měřidlo MET-EE-44230 offline',           'Restaurace U Kohouta · >24h bez dat',        'meters',    NOW() - INTERVAL '4 hours'),
  (t_id, '📄', 'Dávka faktur vystavena',                 '284 faktur · Únor 2026',                     'invoices',  NOW() - INTERVAL '1 day'),
  (t_id, '💰', 'Import bankovního výpisu ČSOB',          '847 transakcí · 835 automaticky spárováno',  'payments',  NOW() - INTERVAL '1 day'),
  (t_id, '⚠️', 'Záloha MASO a.s. vyžaduje přepočet',   'Nová cena ERÚ platná od 1.1.2026',           'advances',  NOW() - INTERVAL '2 days'),
  (t_id, '📧', 'Upomínka odeslána',                     'Restaurace U Kohouta · FAK-2026-04807',      'invoices',  NOW() - INTERVAL '3 days')
ON CONFLICT DO NOTHING;

END $$;
