-- ============================================================
-- GridBill — Seed Data (fixed, no nested DO blocks)
-- Run in: Supabase > SQL Editor
-- ============================================================

-- ── TENANT ──────────────────────────────────────────────────────
INSERT INTO tenants (id, name, ico, vat_number, address, invoice_prefix, invoice_due_days, erp_system, ote_active)
VALUES ('11111111-0000-0000-0000-000000000001', 'ČEZ Distribuce, a.s.', '24729035', 'CZ24729035',
        'Duhová 2/1444, 140 53 Praha 4', 'FAK', 14, 'SAP', true)
ON CONFLICT DO NOTHING;

-- ── CUSTOMERS ───────────────────────────────────────────────────
INSERT INTO customers (id, tenant_id, code, name, type, address, email, phone, bank_account, status, risk_level, balance_czk) VALUES
  ('22222222-0000-0000-0001-000000000001', '11111111-0000-0000-0000-000000000001', 'ZAK-00441', 'Karel Dvořák',           'FO', 'Jiráskova 14, Praha 2',       'karel.dvorak@email.cz',   '+420 602 111 001', 'CZ65 0800 0000 0001 2345 6789', 'active',  'low',    2480),
  ('22222222-0000-0000-0001-000000000002', '11111111-0000-0000-0000-000000000001', 'ZAK-00892', 'MASO a.s.',              'PO', 'Průmyslová 44, Brno',         'info@maso.cz',            '+420 545 222 002', 'CZ12 0100 0000 0092 8800 0001', 'active',  'high', -14800),
  ('22222222-0000-0000-0001-000000000003', '11111111-0000-0000-0000-000000000001', 'ZAK-01204', 'Jana Procházková',        'FO', 'Tylova 8, Ostrava',           'jana.prochaz@email.cz',   '+420 596 333 003', 'CZ44 0300 0000 0001 2204 5678', 'active',  'low',      0),
  ('22222222-0000-0000-0001-000000000004', '11111111-0000-0000-0000-000000000001', 'ZAK-01540', 'BUILDING.cz s.r.o.',     'PO', 'Nová 22, Plzeň',              'billing@building.cz',     '+420 377 444 004', 'CZ81 0600 0000 0054 0100 0001', 'warning', 'medium', -4200),
  ('22222222-0000-0000-0001-000000000005', '11111111-0000-0000-0000-000000000001', 'ZAK-02008', 'Petr Novotný',            'FO', 'K Lesu 3, Olomouc',          'p.novotny@email.cz',      '+420 585 555 005', 'CZ22 0800 0000 0012 3456 7891', 'active',  'low',     800),
  ('22222222-0000-0000-0001-000000000006', '11111111-0000-0000-0000-000000000001', 'ZAK-02344', 'SVJ Horní 12',            'PO', 'Horní 12, Liberec',          'svj.horni12@email.cz',    '+420 485 666 006', 'CZ55 0100 0000 0023 4400 0012', 'active',  'low',    5120),
  ('22222222-0000-0000-0001-000000000007', '11111111-0000-0000-0000-000000000001', 'ZAK-02810', 'Restaurace U Kohouta',    'PO', 'Náměstí 1, Pardubice',       'kohouta@restaurace.cz',   '+420 466 777 007', 'CZ88 0800 0000 0028 1000 0001', 'blocked', 'high', -28400),
  ('22222222-0000-0000-0001-000000000008', '11111111-0000-0000-0000-000000000001', 'ZAK-03102', 'Marie Nováková',          'FO', 'Lipová 5, České Budějovice', 'marie.novakova@email.cz', '+420 387 888 008', 'CZ11 0800 0000 0031 0200 0001', 'active',  'low',      0)
ON CONFLICT DO NOTHING;

-- ── CUSTOMER COMMODITIES ────────────────────────────────────────
INSERT INTO customer_commodities (customer_id, commodity) VALUES
  ('22222222-0000-0000-0001-000000000001', 'EE'),
  ('22222222-0000-0000-0001-000000000001', 'GAS'),
  ('22222222-0000-0000-0001-000000000002', 'EE'),
  ('22222222-0000-0000-0001-000000000002', 'GAS'),
  ('22222222-0000-0000-0001-000000000002', 'HEAT'),
  ('22222222-0000-0000-0001-000000000003', 'EE'),
  ('22222222-0000-0000-0001-000000000003', 'WATER'),
  ('22222222-0000-0000-0001-000000000004', 'EE'),
  ('22222222-0000-0000-0001-000000000004', 'WATER'),
  ('22222222-0000-0000-0001-000000000004', 'HEAT'),
  ('22222222-0000-0000-0001-000000000005', 'GAS'),
  ('22222222-0000-0000-0001-000000000006', 'HEAT'),
  ('22222222-0000-0000-0001-000000000006', 'WATER'),
  ('22222222-0000-0000-0001-000000000007', 'EE'),
  ('22222222-0000-0000-0001-000000000007', 'GAS'),
  ('22222222-0000-0000-0001-000000000008', 'EE')
ON CONFLICT DO NOTHING;

-- ── TARIFFS ─────────────────────────────────────────────────────
INSERT INTO tariffs (tenant_id, code, name, commodity, fixed_fee_czk, unit_price_czk, vat_rate, valid_from) VALUES
  ('11111111-0000-0000-0000-000000000001', 'D01d',    'Jednotarifový – domácnost',    'EE',    213,  1.84,  0.21, '2026-01-01'),
  ('11111111-0000-0000-0000-000000000001', 'D25d',    'Dvoutarifový – akumulace',     'EE',    384,  1.44,  0.21, '2026-01-01'),
  ('11111111-0000-0000-0000-000000000001', 'C35d',    'Malý podnik – dvoutarifový',   'EE',   2200,  1.62,  0.21, '2026-01-01'),
  ('11111111-0000-0000-0000-000000000001', 'D3',      'Domácnost – maloodběr',        'GAS',   104,  1.12,  0.21, '2026-01-01'),
  ('11111111-0000-0000-0000-000000000001', 'VD-DN20', 'Vodoměr DN20 – domácnost',     'WATER',  15, 92.40,  0.15, '2026-01-01'),
  ('11111111-0000-0000-0000-000000000001', 'VD-DN32', 'Vodoměr DN32 – firma',         'WATER',  40, 88.20,  0.15, '2026-01-01'),
  ('11111111-0000-0000-0000-000000000001', 'CZT-A',   'Teplo – bytový dům (základ)',  'HEAT', 1200,   580,  0.15, '2026-01-01'),
  ('11111111-0000-0000-0000-000000000001', 'CZT-B',   'Teplo – bytový dům (tarif B)', 'HEAT', 1500,   640,  0.15, '2026-01-01')
ON CONFLICT DO NOTHING;

-- ── CONTRACTS ───────────────────────────────────────────────────
INSERT INTO contracts (tenant_id, customer_id, opm_id, contract_number, commodity, tariff_code, valid_from, valid_to, status) VALUES
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000001', 'EAN 859182400441',  'SMK-2024-0441', 'EE',    'D25d',    '2024-03-01', '2027-02-28', 'active'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000002', 'EAN 859182400892',  'SMK-2024-0892', 'EE',    'C35d',    '2024-06-15', '2026-06-14', 'active'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000003', 'EIC Z12345678',     'SMK-2023-1204', 'GAS',   'D3',      '2023-01-01', '2025-12-31', 'expiring'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000004', 'KALORIMETR K-2201', 'SMK-2025-1540', 'HEAT',  'CZT-B',   '2025-04-01', '2028-03-31', 'active'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000005', 'VOD-884-002008',    'SMK-2022-2008', 'WATER', 'VD-DN32', '2022-08-12', '2026-08-11', 'active'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000006', 'KALORIMETR K-9901', 'SMK-2025-2344', 'HEAT',  'CZT-A',   '2025-01-01', '2027-12-31', 'active'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000007', 'EAN 859182400230',  'SMK-2021-2810', 'EE',    'C35d',    '2021-03-01', '2024-02-29', 'expired'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000008', 'EAN 859182403102',  'SMK-2023-3102', 'EE',    'D01d',    '2023-07-01', '2026-06-30', 'active')
ON CONFLICT DO NOTHING;

-- ── METERS ──────────────────────────────────────────────────────
INSERT INTO meters (tenant_id, customer_id, meter_code, name, meter_type, commodity, ean_eic, current_reading, reading_unit, meter_status, last_read_at, calibration_date, protocol) VALUES
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000001', 'MET-EE-44101',  'Dvořák Karel',         'Elektroměr 3F',     'EE',    'EAN 859182400441',  14284,  'kWh', 'online',  NOW() - INTERVAL '1 hour',   '2030-04-01', 'DLMS/COSEM · AMI'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000002', 'MET-EE-44102',  'MASO a.s.',            'Elektroměr 3F AMI', 'EE',    'EAN 859182400892',  284128, 'kWh', 'online',  NOW() - INTERVAL '1 hour',   '2031-08-01', 'DLMS/COSEM · AMI'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000003', 'MET-GAS-8801',  'Procházková J.',       'Plynoměr G6',       'GAS',   'EIC Z12345678',     8421,   'm³',  'warning', NOW() - INTERVAL '48 hours', '2027-03-01', 'NB-IoT · denní data'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000005', 'MET-WAT-2201',  'Novotný P.',           'Vodoměr DN20',      'WATER', 'VOD-884-002008',    342,    'm³',  'online',  NOW() - INTERVAL '10 days',  '2026-10-01', 'Wireless M-Bus 868MHz'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000006', 'MET-HEAT-9901', 'SVJ Horní 12',         'Kalorimetr',        'HEAT',  'KALORIMETR K-9901', 124.8,  'GJ',  'online',  NOW() - INTERVAL '2 hours',  '2029-01-01', 'M-Bus wired'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000007', 'MET-EE-44230',  'Restaurace U Kohouta', 'Elektroměr 1F',     'EE',    'EAN 859182400230',  42881,  'kWh', 'offline', NOW() - INTERVAL '5 days',   '2028-06-01', 'DLMS/COSEM'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000004', 'MET-GAS-8802',  'BUILDING.cz s.r.o.',   'Plynoměr G10',      'GAS',   'EIC Z98765432',     14220,  'm³',  'online',  NOW() - INTERVAL '2 hours',  '2028-11-01', 'NB-IoT · denní data'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000008', 'MET-WAT-2205',  'Marie Nováková',       'Vodoměr DN15',      'WATER', 'VOD-881-003102',    185,    'm³',  'online',  NOW() - INTERVAL '12 days',  '2026-08-01', 'Wireless M-Bus 868MHz')
ON CONFLICT DO NOTHING;

-- ── INVOICES ────────────────────────────────────────────────────
INSERT INTO invoices (tenant_id, customer_id, invoice_number, invoice_type, commodity, period_from, period_to, amount_net, vat_rate, status, issued_at, due_at) VALUES
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000001', 'FAK-2026-04812', 'komoditní',        'EE',    '2026-01-01', '2026-01-31',  3538.84, 0.21, 'paid',    NOW() - INTERVAL '21 days', NOW() - INTERVAL '7 days'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000002', 'FAK-2026-04811', 'komoditní',        'EE',    '2026-01-01', '2026-01-31', 23504.13, 0.21, 'overdue', NOW() - INTERVAL '21 days', NOW() - INTERVAL '7 days'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000003', 'FAK-2026-04810', 'komoditní',        'GAS',   '2026-01-01', '2026-01-31',  2578.51, 0.21, 'sent',    NOW() - INTERVAL '21 days', NOW() - INTERVAL '7 days'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000004', 'FAK-2026-04809', 'záloha',           'HEAT',  '2026-02-01', '2026-02-28',  7339.13, 0.15, 'paid',    NOW() - INTERVAL '21 days', NOW() - INTERVAL '7 days'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000006', 'FAK-2026-04808', 'komoditní',        'WATER', '2026-01-01', '2026-01-31',  2504.35, 0.15, 'sent',    NOW() - INTERVAL '21 days', NOW() - INTERVAL '7 days'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000007', 'FAK-2026-04807', 'komoditní',        'EE',    '2026-01-01', '2026-01-31', 10280.99, 0.21, 'overdue', NOW() - INTERVAL '21 days', NOW() - INTERVAL '7 days'),
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0001-000000000008', 'FAK-2026-04806', 'roční vyúčtování', 'EE',    '2025-10-01', '2025-12-31',  3008.26, 0.21, 'paid',    NOW() - INTERVAL '38 days', NOW() - INTERVAL '24 days')
ON CONFLICT DO NOTHING;

-- ── INVOICE ITEMS ───────────────────────────────────────────────
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
  ('11111111-0000-0000-0000-000000000001', 'ZAL-2026-0441', '22222222-0000-0000-0001-000000000001', 'EE',   'D25d',  4560,   1.84, 213,  912,   0.21, '2026-01-01', '2026-12-31', 'active', false),
  ('11111111-0000-0000-0000-000000000001', 'ZAL-2026-0892', '22222222-0000-0000-0001-000000000002', 'EE',   'C35d',  180000, 1.62, 2200, 24000, 0.21, '2026-01-01', '2026-12-31', 'active', true),
  ('11111111-0000-0000-0000-000000000001', 'ZAL-2026-1204', '22222222-0000-0000-0001-000000000003', 'GAS',  'D3',    18000,  1.12, 104,  1680,  0.21, '2026-01-01', '2026-12-31', 'active', false),
  ('11111111-0000-0000-0000-000000000001', 'ZAL-2026-2344', '22222222-0000-0000-0001-000000000006', 'HEAT', 'CZT-A', 0,      0,    0,    8440,  0.15, '2026-01-01', '2026-12-31', 'active', false)
ON CONFLICT DO NOTHING;

-- ── ADVANCE MONTHS (generated via generate_series) ──────────────
INSERT INTO advance_months (schedule_id, month_number, due_date, amount_net, vat_rate, amount_paid, paid_date, payment_status)
SELECT
  s.id,
  g.m,
  ('2026-01-15'::date + ((g.m - 1) || ' months')::interval)::date,
  912,
  0.21,
  CASE WHEN g.m < EXTRACT(MONTH FROM NOW()) THEN 1103.52 ELSE 0 END,
  CASE WHEN g.m < EXTRACT(MONTH FROM NOW())
       THEN ('2026-01-17'::date + ((g.m - 1) || ' months')::interval)::date
       ELSE NULL END,
  CASE
    WHEN g.m < EXTRACT(MONTH FROM NOW())  THEN 'paid'::payment_status_t
    WHEN g.m = EXTRACT(MONTH FROM NOW())  THEN 'pending'::payment_status_t
    ELSE 'future'::payment_status_t
  END
FROM advance_schedules s
CROSS JOIN generate_series(1, 12) AS g(m)
WHERE s.schedule_code = 'ZAL-2026-0441'
ON CONFLICT DO NOTHING;

INSERT INTO advance_months (schedule_id, month_number, due_date, amount_net, vat_rate, amount_paid, paid_date, payment_status)
SELECT
  s.id,
  g.m,
  ('2026-01-15'::date + ((g.m - 1) || ' months')::interval)::date,
  1680,
  0.21,
  CASE WHEN g.m < EXTRACT(MONTH FROM NOW()) THEN 2032.80 ELSE 0 END,
  CASE WHEN g.m < EXTRACT(MONTH FROM NOW())
       THEN ('2026-01-17'::date + ((g.m - 1) || ' months')::interval)::date
       ELSE NULL END,
  CASE
    WHEN g.m < EXTRACT(MONTH FROM NOW())  THEN 'paid'::payment_status_t
    WHEN g.m = EXTRACT(MONTH FROM NOW())  THEN 'pending'::payment_status_t
    ELSE 'future'::payment_status_t
  END
FROM advance_schedules s
CROSS JOIN generate_series(1, 12) AS g(m)
WHERE s.schedule_code = 'ZAL-2026-1204'
ON CONFLICT DO NOTHING;

-- ── BANK PAYMENTS ───────────────────────────────────────────────
INSERT INTO bank_payments (tenant_id, payment_code, variable_symbol, amount_czk, sender_name, sender_account, received_at, matched) VALUES
  ('11111111-0000-0000-0000-000000000001', 'PLT-001', '202600441', 4280,  'Karel Dvořák',    'CZ65 0800 ....4589', NOW() - INTERVAL '2 days', true),
  ('11111111-0000-0000-0000-000000000001', 'PLT-002', '202600892', 28440, 'MASO a.s.',       'CZ12 0100 ....8822', NOW() - INTERVAL '1 day',  false),
  ('11111111-0000-0000-0000-000000000001', 'PLT-003', '',          3120,  'Procházková Jana','CZ44 0300 ....1122', NOW() - INTERVAL '1 day',  false),
  ('11111111-0000-0000-0000-000000000001', 'PLT-004', '202601204', 3120,  'Jana Procházková','CZ44 0300 ....1122', NOW() - INTERVAL '3 days', true),
  ('11111111-0000-0000-0000-000000000001', 'PLT-005', '',          880,   '—',               'CZ99 0800 ....4421', NOW() - INTERVAL '1 day',  false)
ON CONFLICT DO NOTHING;

UPDATE bank_payments
SET matched_invoice_id = (SELECT id FROM invoices WHERE invoice_number = 'FAK-2026-04812'),
    matched_at = NOW() - INTERVAL '2 days'
WHERE payment_code = 'PLT-001'
  AND matched_invoice_id IS NULL;

-- ── BUILDINGS (RÚNT) ─────────────────────────────────────────────
INSERT INTO buildings (id, tenant_id, name, year, unit_count, total_cost_czk, deliverer_customer_id, status) VALUES
  ('33333333-0000-0000-0001-000000000001', '11111111-0000-0000-0000-000000000001', 'Horní 12, Liberec', 2025, 24, 248440, '22222222-0000-0000-0001-000000000006', 'open'),
  ('33333333-0000-0000-0001-000000000002', '11111111-0000-0000-0000-000000000001', 'Nábřežní 8, Praha', 2025, 12, 124800, '22222222-0000-0000-0001-000000000004', 'closed')
ON CONFLICT DO NOTHING;

INSERT INTO building_units (building_id, unit_name, ean, cost_fixed, cost_variable) VALUES
  ('33333333-0000-0000-0001-000000000001', 'Byt 1/2 (52 m²)',     'KALORIMETR K-0101', 2844, 7122),
  ('33333333-0000-0000-0001-000000000001', 'Byt 2/4 (78 m²)',     'KALORIMETR K-0102', 4266, 8440),
  ('33333333-0000-0000-0001-000000000001', 'Byt 3/6 (45 m²)',     'KALORIMETR K-0103', 2466, 5880),
  ('33333333-0000-0000-0001-000000000001', 'Nebytový – prodejna', 'KALORIMETR K-0104', 3622, 4200),
  ('33333333-0000-0000-0001-000000000002', 'Byt 1/1 (64 m²)',     'KALORIMETR K-0201', 3480, 6800),
  ('33333333-0000-0000-0001-000000000002', 'Byt 1/3 (48 m²)',     'KALORIMETR K-0202', 2610, 4900)
ON CONFLICT DO NOTHING;

-- ── INTEGRATIONS ────────────────────────────────────────────────
INSERT INTO integrations (tenant_id, icon, name, description, status, last_sync) VALUES
  ('11111111-0000-0000-0000-000000000001', '⚡', 'OTE Datahub',   'Registrace OPM, 15min data, fakturační dávky', 'online',   NOW() - INTERVAL '5 minutes'),
  ('11111111-0000-0000-0000-000000000001', '🏦', 'ČSOB Bank API', 'Bankovní výpisy MT940, příkazy k úhradě',     'online',   NOW() - INTERVAL '1 hour'),
  ('11111111-0000-0000-0000-000000000001', '🏭', 'SAP ERP',       'Agregovaný export faktur a DPH',              'online',   NOW() - INTERVAL '30 minutes'),
  ('11111111-0000-0000-0000-000000000001', '📡', 'AMI Head-End',  '15min data z 8 440 elektroměrů',             'degraded', NOW() - INTERVAL '2 hours'),
  ('11111111-0000-0000-0000-000000000001', '💧', 'M-Bus Gateway', 'Kalorimetry a vodoměry',                      'online',   NOW() - INTERVAL '1 hour'),
  ('11111111-0000-0000-0000-000000000001', '📧', 'SendGrid',      'E-mailová komunikace se zákazníky',           'online',   NOW() - INTERVAL '10 minutes')
ON CONFLICT DO NOTHING;

-- ── ACTIVITY LOG ────────────────────────────────────────────────
INSERT INTO activity_log (tenant_id, icon, title, detail, entity, created_at) VALUES
  ('11111111-0000-0000-0000-000000000001', '✅', 'Faktura FAK-2026-04812 zaplacena',    'Karel Dvořák · 4 280 Kč',                  'invoices', NOW() - INTERVAL '2 hours'),
  ('11111111-0000-0000-0000-000000000001', '🔴', 'Měřidlo MET-EE-44230 offline',         'Restaurace U Kohouta · >24h bez dat',       'meters',   NOW() - INTERVAL '4 hours'),
  ('11111111-0000-0000-0000-000000000001', '📄', 'Dávka faktur vystavena',               '284 faktur · Únor 2026',                    'invoices', NOW() - INTERVAL '1 day'),
  ('11111111-0000-0000-0000-000000000001', '💰', 'Import bankovního výpisu ČSOB',        '847 transakcí · 835 automaticky spárováno', 'payments', NOW() - INTERVAL '1 day'),
  ('11111111-0000-0000-0000-000000000001', '⚠️','Záloha MASO a.s. vyžaduje přepočet',  'Nová cena ERÚ platná od 1.1.2026',          'advances', NOW() - INTERVAL '2 days'),
  ('11111111-0000-0000-0000-000000000001', '📧', 'Upomínka odeslána',                   'Restaurace U Kohouta · FAK-2026-04807',     'invoices', NOW() - INTERVAL '3 days')
ON CONFLICT DO NOTHING;
