-- ============================================================
-- GridBill — Create Demo Users (idempotent, safe to re-run)
-- ============================================================

-- Clean up first (safe re-run)
DELETE FROM user_tenants WHERE user_id IN (
  '99999999-0000-0000-0001-000000000001',
  '99999999-0000-0000-0001-000000000002',
  '99999999-0000-0000-0001-000000000003'
);
DELETE FROM app_users WHERE id IN (
  '99999999-0000-0000-0001-000000000001',
  '99999999-0000-0000-0001-000000000002',
  '99999999-0000-0000-0001-000000000003'
);
DELETE FROM auth.identities WHERE user_id IN (
  '99999999-0000-0000-0001-000000000001',
  '99999999-0000-0000-0001-000000000002',
  '99999999-0000-0000-0001-000000000003'
);
DELETE FROM auth.users WHERE id IN (
  '99999999-0000-0000-0001-000000000001',
  '99999999-0000-0000-0001-000000000002',
  '99999999-0000-0000-0001-000000000003'
);

-- Step 1: auth.users
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data,
  is_super_admin, role, aud
) VALUES
  (
    '99999999-0000-0000-0001-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'admin@energo.cz',
    crypt('Admin1234', gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Jan Novák","role":"admin"}',
    false, 'authenticated', 'authenticated'
  ),
  (
    '99999999-0000-0000-0001-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'operator@energo.cz',
    crypt('Operator1234', gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Eva Marková","role":"billing_operator"}',
    false, 'authenticated', 'authenticated'
  ),
  (
    '99999999-0000-0000-0001-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'odectare@energo.cz',
    crypt('Reader1234', gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Pavel Kříž","role":"meter_reader"}',
    false, 'authenticated', 'authenticated'
  );

-- Step 2: auth.identities
INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
) VALUES
  (
    '99999999-0000-0000-0001-000000000001',
    '99999999-0000-0000-0001-000000000001',
    '{"sub":"99999999-0000-0000-0001-000000000001","email":"admin@energo.cz"}',
    'email', 'admin@energo.cz', NOW(), NOW(), NOW()
  ),
  (
    '99999999-0000-0000-0001-000000000002',
    '99999999-0000-0000-0001-000000000002',
    '{"sub":"99999999-0000-0000-0001-000000000002","email":"operator@energo.cz"}',
    'email', 'operator@energo.cz', NOW(), NOW(), NOW()
  ),
  (
    '99999999-0000-0000-0001-000000000003',
    '99999999-0000-0000-0001-000000000003',
    '{"sub":"99999999-0000-0000-0001-000000000003","email":"odectare@energo.cz"}',
    'email', 'odectare@energo.cz', NOW(), NOW(), NOW()
  );

-- Step 3: app_users
INSERT INTO app_users (id, full_name, email, role, status) VALUES
  ('99999999-0000-0000-0001-000000000001', 'Jan Novák',   'admin@energo.cz',    'admin',            'active'),
  ('99999999-0000-0000-0001-000000000002', 'Eva Marková', 'operator@energo.cz', 'billing_operator', 'active'),
  ('99999999-0000-0000-0001-000000000003', 'Pavel Kříž',  'odectare@energo.cz', 'meter_reader',     'active');

-- Step 4: user_tenants
INSERT INTO user_tenants (user_id, tenant_id) VALUES
  ('99999999-0000-0000-0001-000000000001', '11111111-0000-0000-0000-000000000001'),
  ('99999999-0000-0000-0001-000000000002', '11111111-0000-0000-0000-000000000001'),
  ('99999999-0000-0000-0001-000000000003', '11111111-0000-0000-0000-000000000001');

-- ============================================================
-- admin@energo.cz      /  Admin1234
-- operator@energo.cz   /  Operator1234
-- odectare@energo.cz   /  Reader1234
-- ============================================================
