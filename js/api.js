// js/api.js
// Data access layer. All Supabase queries live here.
// Each function returns the data array (throws on error).

import { sbReady } from './config.js';

async function sb() { return sbReady; }

// ─── helpers ────────────────────────────────────────────────────────────────

async function query(fn) {
  const db = await sb();
  const { data, error } = await fn(db);
  if (error) throw error;
  return data;
}

// ─── AUTH ────────────────────────────────────────────────────────────────────

export async function signIn(email, password) {
  const db = await sb();
  const { data, error } = await db.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  const db = await sb();
  const { error } = await db.auth.signOut();
  if (error) throw error;
}

export async function getSession() {
  const db = await sb();
  const { data: { session } } = await db.auth.getSession();
  return session;
}

export async function getUser() {
  const db = await sb();
  const { data: { user } } = await db.auth.getUser();
  return user;
}

// ─── TENANTS ─────────────────────────────────────────────────────────────────

export async function getTenants() {
  return query(db => db.from('tenants').select('*').order('name'));
}

export async function getTenant(id) {
  return query(db => db.from('tenants').select('*').eq('id', id).single());
}

// ─── CUSTOMERS ───────────────────────────────────────────────────────────────

export async function getCustomers({ search = '', status = '', commodity = '' } = {}) {
  return query(db => {
    let q = db
      .from('customers')
      .select(`
        id, code, name, type, address, status, balance_czk, risk_level,
        customer_commodities ( commodity )
      `)
      .order('name');

    if (status)    q = q.eq('status', status);
    if (search)    q = q.or(`name.ilike.%${search}%,code.ilike.%${search}%`);
    return q;
  });
}

export async function getCustomer(id) {
  return query(db =>
    db.from('customers')
      .select(`
        *,
        customer_commodities ( commodity ),
        contracts ( id, contract_number, commodity, status ),
        invoices ( id, invoice_number, period_from, period_to, total_czk, status )
      `)
      .eq('id', id)
      .single()
  );
}

export async function upsertCustomer(data) {
  return query(db => db.from('customers').upsert(data).select().single());
}

// ─── CONTRACTS ───────────────────────────────────────────────────────────────

export async function getContracts({ customerId = null, status = '' } = {}) {
  return query(db => {
    let q = db
      .from('contracts')
      .select(`
        id, contract_number, customer_id, opm_id, commodity,
        tariff_code, valid_from, valid_to, status,
        customers ( name )
      `)
      .order('valid_from', { ascending: false });

    if (customerId) q = q.eq('customer_id', customerId);
    if (status)     q = q.eq('status', status);
    return q;
  });
}

// ─── METERS ──────────────────────────────────────────────────────────────────

export async function getMeters({ commodity = '', status = '', search = '' } = {}) {
  return query(db => {
    let q = db
      .from('meters')
      .select(`
        id, meter_code, name, meter_type, commodity,
        ean_eic, current_reading, reading_unit,
        meter_status, last_read_at, calibration_date,
        protocol
      `)
      .order('meter_code');

    if (commodity && commodity !== 'all') q = q.eq('commodity', commodity);
    if (status)    q = q.eq('meter_status', status);
    if (search)    q = q.or(`meter_code.ilike.%${search}%,name.ilike.%${search}%`);
    return q;
  });
}

export async function getMeterReadings(meterId, limit = 12) {
  return query(db =>
    db.from('meter_readings')
      .select('*')
      .eq('meter_id', meterId)
      .order('read_at', { ascending: false })
      .limit(limit)
  );
}

// ─── TARIFFS ─────────────────────────────────────────────────────────────────

export async function getTariffs({ commodity = '' } = {}) {
  return query(db => {
    let q = db.from('tariffs').select('*').order('commodity, code');
    if (commodity) q = q.eq('commodity', commodity);
    return q;
  });
}

// ─── INVOICES ────────────────────────────────────────────────────────────────

export async function getInvoices({ status = '', commodity = '', search = '' } = {}) {
  return query(db => {
    let q = db
      .from('invoices')
      .select(`
        id, invoice_number, customer_id, commodity, invoice_type,
        period_from, period_to, amount_net, vat_amount, total_czk,
        status, issued_at, due_at,
        customers ( name )
      `)
      .order('issued_at', { ascending: false });

    if (status)    q = q.eq('status', status);
    if (commodity) q = q.eq('commodity', commodity);
    if (search)    q = q.or(`invoice_number.ilike.%${search}%,customers.name.ilike.%${search}%`);
    return q;
  });
}

export async function getInvoice(id) {
  return query(db =>
    db.from('invoices')
      .select(`*, invoice_items(*), customers(name, address)`)
      .eq('id', id)
      .single()
  );
}

export async function getInvoiceStats() {
  return query(db =>
    db.from('invoice_stats').select('*').single()
  );
}

export async function createInvoice(data) {
  return query(db => db.from('invoices').insert(data).select().single());
}

// ─── ADVANCE SCHEDULES ───────────────────────────────────────────────────────

export async function getAdvanceSchedules({ status = '' } = {}) {
  return query(db => {
    let q = db
      .from('advance_schedules')
      .select(`
        id, schedule_code, customer_id, contract_id, commodity, tariff_code,
        annual_kwh, price_per_kwh, fixed_monthly_czk,
        amount_net, vat_rate, amount_gross,
        period_from, period_to, status, recalc_needed,
        customers ( name )
      `)
      .order('customer_id');

    if (status) q = q.eq('status', status);
    return q;
  });
}

export async function getAdvanceMonths(scheduleId) {
  return query(db =>
    db.from('advance_months')
      .select('*')
      .eq('schedule_id', scheduleId)
      .order('month_number')
  );
}

export async function approveRecalc(scheduleId, newAmount) {
  return query(db =>
    db.from('advance_schedules')
      .update({ amount_net: newAmount, recalc_needed: false, recalc_approved_at: new Date().toISOString() })
      .eq('id', scheduleId)
      .select()
      .single()
  );
}

// ─── PAYMENTS ────────────────────────────────────────────────────────────────

export async function getBankPayments({ matched = null } = {}) {
  return query(db => {
    let q = db
      .from('bank_payments')
      .select(`
        id, payment_code, variable_symbol, amount_czk,
        sender_name, sender_account, received_at,
        matched, matched_invoice_id,
        invoices ( invoice_number )
      `)
      .order('received_at', { ascending: false });

    if (matched !== null) q = q.eq('matched', matched);
    return q;
  });
}

export async function getOpenInvoices() {
  return query(db =>
    db.from('invoices')
      .select('id, invoice_number, total_czk, customers(name)')
      .in('status', ['sent', 'overdue'])
      .order('due_at')
  );
}

export async function matchPayment(paymentId, invoiceId) {
  return query(db =>
    db.from('bank_payments')
      .update({ matched: true, matched_invoice_id: invoiceId, matched_at: new Date().toISOString() })
      .eq('id', paymentId)
      .select()
      .single()
  );
}

// ─── RÚNT / BUILDINGS ────────────────────────────────────────────────────────

export async function getBuildings(year) {
  return query(db =>
    db.from('buildings')
      .select(`
        id, name, year, unit_count, total_cost_czk, deliverer_customer_id, status,
        building_units ( id, unit_name, ean, cost_fixed, cost_variable, cost_total )
      `)
      .eq('year', year)
      .order('name')
  );
}

// ─── DASHBOARD ───────────────────────────────────────────────────────────────

export async function getDashboardKpis() {
  return query(db => db.from('dashboard_kpis').select('*').single());
}

export async function getDashboardActivity(limit = 8) {
  return query(db =>
    db.from('activity_log')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
  );
}

// ─── USERS / ADMIN ───────────────────────────────────────────────────────────

export async function getAppUsers() {
  return query(db =>
    db.from('app_users')
      .select(`
        id, full_name, email, role, status, last_login_at,
        user_tenants ( tenants(name) )
      `)
      .order('full_name')
  );
}

export async function getIntegrationStatus() {
  return query(db =>
    db.from('integrations').select('*').order('name')
  );
}
