-- ============================================================
-- GridBill — Row Level Security (RLS)
-- Run AFTER 00_schema.sql
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- HELPER: current user's tenant IDs
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION auth_tenant_ids()
RETURNS UUID[] AS $$
  SELECT ARRAY(
    SELECT tenant_id FROM user_tenants
    WHERE user_id = auth.uid()
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ──────────────────────────────────────────────────────────
-- HELPER: current user's role
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION auth_user_role()
RETURNS user_role_t AS $$
  SELECT role FROM app_users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ──────────────────────────────────────────────────────────
-- ENABLE RLS on all tables
-- ──────────────────────────────────────────────────────────

ALTER TABLE tenants           ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users         ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tenants      ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_commodities ENABLE ROW LEVEL SECURITY;
ALTER TABLE tariffs           ENABLE ROW LEVEL SECURITY;
ALTER TABLE supply_points     ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE meters            ENABLE ROW LEVEL SECURITY;
ALTER TABLE meter_readings    ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices          ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items     ENABLE ROW LEVEL SECURITY;
ALTER TABLE advance_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE advance_months    ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_payments     ENABLE ROW LEVEL SECURITY;
ALTER TABLE buildings         ENABLE ROW LEVEL SECURITY;
ALTER TABLE building_units    ENABLE ROW LEVEL SECURITY;
ALTER TABLE integrations      ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log      ENABLE ROW LEVEL SECURITY;

-- ──────────────────────────────────────────────────────────
-- TENANTS — read own tenants only
-- ──────────────────────────────────────────────────────────

CREATE POLICY tenants_select ON tenants
  FOR SELECT TO authenticated
  USING (id = ANY(auth_tenant_ids()));

-- ──────────────────────────────────────────────────────────
-- APP_USERS — read own record; admin reads all in tenant
-- ──────────────────────────────────────────────────────────

CREATE POLICY app_users_self ON app_users
  FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY app_users_admin ON app_users
  FOR SELECT TO authenticated
  USING (auth_user_role() = 'admin');

-- ──────────────────────────────────────────────────────────
-- TENANT-SCOPED TABLES — standard pattern
-- All rows must belong to a tenant the user has access to.
-- ──────────────────────────────────────────────────────────

-- customers
CREATE POLICY customers_select ON customers
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY customers_insert ON customers
  FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id = ANY(auth_tenant_ids()) AND
    auth_user_role() IN ('admin', 'billing_operator')
  );

CREATE POLICY customers_update ON customers
  FOR UPDATE TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- customer_commodities
CREATE POLICY cc_select ON customer_commodities
  FOR SELECT TO authenticated
  USING (
    customer_id IN (SELECT id FROM customers WHERE tenant_id = ANY(auth_tenant_ids()))
  );

CREATE POLICY cc_modify ON customer_commodities
  FOR ALL TO authenticated
  USING (
    customer_id IN (SELECT id FROM customers WHERE tenant_id = ANY(auth_tenant_ids()))
  )
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- tariffs
CREATE POLICY tariffs_select ON tariffs
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY tariffs_modify ON tariffs
  FOR ALL TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() = 'admin');

-- supply_points
CREATE POLICY sp_select ON supply_points
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

-- contracts
CREATE POLICY contracts_select ON contracts
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY contracts_modify ON contracts
  FOR ALL TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- meters
CREATE POLICY meters_select ON meters
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY meters_modify ON meters
  FOR ALL TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator', 'meter_reader'));

-- meter_readings
CREATE POLICY readings_select ON meter_readings
  FOR SELECT TO authenticated
  USING (
    meter_id IN (SELECT id FROM meters WHERE tenant_id = ANY(auth_tenant_ids()))
  );

CREATE POLICY readings_insert ON meter_readings
  FOR INSERT TO authenticated
  WITH CHECK (
    meter_id IN (SELECT id FROM meters WHERE tenant_id = ANY(auth_tenant_ids()))
    AND auth_user_role() IN ('admin', 'billing_operator', 'meter_reader')
  );

-- invoices
CREATE POLICY invoices_select ON invoices
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY invoices_insert ON invoices
  FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id = ANY(auth_tenant_ids()) AND
    auth_user_role() IN ('admin', 'billing_operator')
  );

CREATE POLICY invoices_update ON invoices
  FOR UPDATE TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- auditor may only SELECT
CREATE POLICY invoices_auditor ON invoices
  FOR SELECT TO authenticated
  USING (auth_user_role() = 'auditor' AND tenant_id = ANY(auth_tenant_ids()));

-- invoice_items
CREATE POLICY inv_items_select ON invoice_items
  FOR SELECT TO authenticated
  USING (
    invoice_id IN (SELECT id FROM invoices WHERE tenant_id = ANY(auth_tenant_ids()))
  );

CREATE POLICY inv_items_modify ON invoice_items
  FOR ALL TO authenticated
  USING (
    invoice_id IN (SELECT id FROM invoices WHERE tenant_id = ANY(auth_tenant_ids()))
  )
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- advance_schedules
CREATE POLICY adv_sch_select ON advance_schedules
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY adv_sch_modify ON advance_schedules
  FOR ALL TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- advance_months
CREATE POLICY adv_mon_select ON advance_months
  FOR SELECT TO authenticated
  USING (
    schedule_id IN (
      SELECT id FROM advance_schedules WHERE tenant_id = ANY(auth_tenant_ids())
    )
  );

CREATE POLICY adv_mon_modify ON advance_months
  FOR ALL TO authenticated
  USING (
    schedule_id IN (
      SELECT id FROM advance_schedules WHERE tenant_id = ANY(auth_tenant_ids())
    )
  )
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- bank_payments
CREATE POLICY payments_select ON bank_payments
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY payments_insert ON bank_payments
  FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id = ANY(auth_tenant_ids()) AND
    auth_user_role() IN ('admin', 'billing_operator')
  );

CREATE POLICY payments_update ON bank_payments
  FOR UPDATE TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- buildings
CREATE POLICY buildings_select ON buildings
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY buildings_modify ON buildings
  FOR ALL TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() IN ('admin', 'billing_operator'));

-- building_units
CREATE POLICY units_select ON building_units
  FOR SELECT TO authenticated
  USING (
    building_id IN (SELECT id FROM buildings WHERE tenant_id = ANY(auth_tenant_ids()))
  );

-- integrations
CREATE POLICY integrations_select ON integrations
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY integrations_admin ON integrations
  FOR ALL TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()))
  WITH CHECK (auth_user_role() = 'admin');

-- activity_log
CREATE POLICY activity_select ON activity_log
  FOR SELECT TO authenticated
  USING (tenant_id = ANY(auth_tenant_ids()));

CREATE POLICY activity_insert ON activity_log
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id = ANY(auth_tenant_ids()));
