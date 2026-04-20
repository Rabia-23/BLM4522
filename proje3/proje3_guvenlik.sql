-- ============================================================
-- BLM4522 - Proje 3: Veritabani Guvenligi ve Erisim Kontrolu
-- Veritabani: Northwind (PostgreSQL)
-- Hazirlayan: Rabia Sevval Yasar
-- Tarih: Nisan 2026
-- ============================================================


-- ============================================================
-- BOLUM 0: GUVENLIK ACIGI TESPITI
-- Veritabaninin mevcut guvenlik durumunun belgelenmesi
-- ============================================================

-- Mevcut roller ve kullanicilar (sadece superuser olmali)
\du

-- Tablolara tanimli yetki var mi?
SELECT grantee, privilege_type, table_name
FROM information_schema.role_table_grants
WHERE table_name IN ('employees', 'customers', 'orders')
  AND grantee NOT IN ('rabiasevvalyasar', 'PUBLIC')
ORDER BY table_name;
-- Beklenen sonuc: 0 satir (hic yetki kisitlamasi yok)

-- Sifreli alan var mi?
SELECT table_name, column_name
FROM information_schema.columns
WHERE column_name ILIKE '%password%'
   OR column_name ILIKE '%encrypt%'
   OR column_name ILIKE '%secret%'
ORDER BY table_name;
-- Beklenen sonuc: Northwind tablolarinda sifreli alan yok

-- RLS politikasi var mi?
SELECT * FROM pg_policies;
-- Beklenen sonuc: 0 satir (hic RLS politikasi yok)

-- Hassas veri iceren employees tablosu
SELECT * FROM employees LIMIT 3;
-- home_phone, birth_date, address, notes duz metin olarak gorunuyor


-- ============================================================
-- BOLUM 1: ROL TABANLI ERISIM KONTROLU (RBAC)
-- ============================================================

-- 1.1 Rolleri olustur
CREATE ROLE readonly_role;
CREATE ROLE dataentry_role;
CREATE ROLE admin_role;

-- 1.2 Yetkileri ata
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO dataentry_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;

-- 1.3 Kullanicilari olustur ve rollere ata
CREATE USER analyst WITH PASSWORD 'analyst123';
CREATE USER dataentry WITH PASSWORD 'dataentry123';
CREATE USER dbadmin WITH PASSWORD 'dbadmin123';

GRANT readonly_role TO analyst;
GRANT dataentry_role TO dataentry;
GRANT admin_role TO dbadmin;

-- 1.4 Rolleri dogrula
\du

SELECT grantee, privilege_type, table_name
FROM information_schema.role_table_grants
WHERE grantee = 'readonly_role'
LIMIT 5;

-- 1.5 Erisim testi (analyst kullanicisiyla baglanti)
-- psql -d northwind -U analyst
-- SELECT * FROM customers LIMIT 3;           -- Basarili olmali
-- INSERT INTO customers (customer_id, company_name)
-- VALUES ('TEST', 'Test');                   -- HATA: permission denied olmali


-- ============================================================
-- BOLUM 2: VERI SIFRELEME (pgcrypto - AES-128)
-- ============================================================

-- 2.1 pgcrypto eklentisini etkinlestir
CREATE EXTENSION pgcrypto;

-- 2.2 Sifreli sutun ekle
ALTER TABLE employees ADD COLUMN home_phone_encrypted TEXT;

-- 2.3 Mevcut telefon verilerini sifrele
UPDATE employees
SET home_phone_encrypted = encode(
  encrypt(home_phone::bytea, 'gizlianahtar'::bytea, 'aes'),
  'base64'
)
WHERE home_phone IS NOT NULL;

-- 2.4 Duz metin sutunu gizle
UPDATE employees SET home_phone = '***GIZLI***';

-- 2.5 Karsilastir: duz metin vs sifreli
SELECT first_name, home_phone, home_phone_encrypted
FROM employees LIMIT 3;

-- 2.6 Dogru anahtar ile sifre coz
SELECT first_name,
  convert_from(
    decrypt(
      decode(home_phone_encrypted, 'base64'),
      'gizlianahtar'::bytea,
      'aes'
    ),
    'UTF8'
  ) AS gercek_telefon
FROM employees LIMIT 3;


-- ============================================================
-- BOLUM 3: SQL INJECTION TESTI VE KORUNMA
-- ============================================================

-- 3.1 Savunmasiz sorgu ornegi
-- Saldiri: ' OR '1'='1 girdisiyle tum tablo dokuluyor
SELECT * FROM customers
WHERE customer_id = '' OR '1'='1'
LIMIT 5;
-- Sonuc: Tum musteriler dondu - tehlikeli!

-- 3.2 Guvenli yontem: parametreli sorgu
PREPARE guvenli_sorgu AS
SELECT * FROM customers WHERE customer_id = $1;

-- Normal kullanim
EXECUTE guvenli_sorgu('ALFKI');

-- Saldiri denemesi (etkisiz kalir)
EXECUTE guvenli_sorgu(''' OR ''1''=''1');
-- Sonuc: 0 satir dondu - SQL Injection engellendi!

DEALLOCATE guvenli_sorgu;


-- ============================================================
-- BOLUM 4: AUDIT LOG SISTEMI
-- ============================================================

-- 4.1 Audit log tablosu
CREATE TABLE audit_log (
    id           SERIAL PRIMARY KEY,
    tablo_adi    TEXT,
    islem        TEXT,
    kullanici    TEXT,
    eski_deger   TEXT,
    yeni_deger   TEXT,
    islem_zamani TIMESTAMPTZ DEFAULT now()
);

-- 4.2 Trigger fonksiyonu
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (tablo_adi, islem, kullanici, yeni_deger)
        VALUES (TG_TABLE_NAME, 'INSERT', current_user, row_to_json(NEW)::text);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (tablo_adi, islem, kullanici, eski_deger, yeni_deger)
        VALUES (TG_TABLE_NAME, 'UPDATE', current_user,
                row_to_json(OLD)::text, row_to_json(NEW)::text);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (tablo_adi, islem, kullanici, eski_deger)
        VALUES (TG_TABLE_NAME, 'DELETE', current_user, row_to_json(OLD)::text);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4.3 Trigger'i customers tablosuna bagla
CREATE TRIGGER customers_audit
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- 4.4 Test: INSERT, UPDATE, DELETE
INSERT INTO customers (customer_id, company_name, contact_name, country)
VALUES ('TEST1', 'Test Sirketi', 'Ali Yilmaz', 'Turkey');

UPDATE customers
SET contact_name = 'Ayse Yilmaz'
WHERE customer_id = 'TEST1';

DELETE FROM customers
WHERE customer_id = 'TEST1';

-- 4.5 Audit log sonuclari
SELECT id, tablo_adi, islem, kullanici, islem_zamani
FROM audit_log;

-- 4.6 Detayli log: eski ve yeni degerler
SELECT id, islem, eski_deger, yeni_deger
FROM audit_log;


-- ============================================================
-- BOLUM 5: ROW LEVEL SECURITY (RLS)
-- Satir Duzeyinde Erisim Kontrolu
-- ============================================================

-- 5.1 Senaryo: her bolge sorumlusu sadece
--     kendi ulkesinin siparislerini gorebilsin

-- Ulke dagilimini kontrol et
SELECT ship_country, COUNT(*) as sayi
FROM orders
GROUP BY ship_country
ORDER BY sayi DESC;

-- 5.2 Bolge sorumlulari
CREATE USER us_manager WITH PASSWORD 'us123';
CREATE USER de_manager WITH PASSWORD 'de123';
CREATE USER br_manager WITH PASSWORD 'br123';

GRANT CONNECT ON DATABASE northwind TO us_manager, de_manager, br_manager;
GRANT USAGE ON SCHEMA public TO us_manager, de_manager, br_manager;
GRANT SELECT ON orders TO us_manager, de_manager, br_manager;

-- 5.3 RLS'i etkinlestir
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 5.4 Her kullanici icin politika tanimla
CREATE POLICY us_only ON orders
    FOR SELECT TO us_manager
    USING (ship_country = 'USA');

CREATE POLICY de_only ON orders
    FOR SELECT TO de_manager
    USING (ship_country = 'Germany');

CREATE POLICY br_only ON orders
    FOR SELECT TO br_manager
    USING (ship_country = 'Brazil');

-- 5.5 Politikalari listele
SELECT tablename, policyname, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'orders';

-- 5.6 RLS testi
-- Super kullanici: tum ulkeler
SELECT ship_country, COUNT(*) FROM orders
GROUP BY ship_country ORDER BY COUNT(*) DESC LIMIT 5;

-- us_manager: sadece USA
SET ROLE us_manager;
SELECT ship_country, COUNT(*) FROM orders GROUP BY ship_country;
RESET ROLE;

-- de_manager: sadece Germany
SET ROLE de_manager;
SELECT ship_country, COUNT(*) FROM orders GROUP BY ship_country;
RESET ROLE;

-- br_manager: sadece Brazil
SET ROLE br_manager;
SELECT ship_country, COUNT(*) FROM orders GROUP BY ship_country;
RESET ROLE;
