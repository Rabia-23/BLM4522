-- ============================================================
-- BLM4522 - Proje 2: Veritabani Yedekleme ve Felaketten Kurtarma
-- Veritabani: Northwind (PostgreSQL)
-- Hazirlayan: Rabia Sevval Yasar
-- Tarih: 14.05.2026
-- ============================================================
-- NOT: Yedek alma ve geri yukleme islemleri pgAdmin arayuzu
--      uzerinden yapilmaktadir. Bu dosya SQL adimlarini icerir.
-- ============================================================


-- ============================================================
-- BOLUM 1: YEDEKLEME ONCESI DURUM TESPITI
-- ============================================================

-- 1.1 Mevcut tablolari listele
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 1.2 Kritik tablolarin kayit sayilari (yedek oncesi)
SELECT 'customers'    AS tablo, COUNT(*) AS kayit FROM customers
UNION ALL
SELECT 'orders',                COUNT(*) FROM orders
UNION ALL
SELECT 'order_details',         COUNT(*) FROM order_details
UNION ALL
SELECT 'products',              COUNT(*) FROM products
UNION ALL
SELECT 'employees',             COUNT(*) FROM employees;
-- Bu sayilari not al -- geri yuklemeden sonra karsilastirilacak


-- ============================================================
-- BOLUM 2: TAM YEDEKLEME (pgAdmin uzerinden)
-- ============================================================
-- pgAdmin adimlari:
-- 1. northwind veritabanina sag tikla
-- 2. Backup... sec
-- 3. Filename: northwind_tam_yedek.backup
-- 4. Format: Custom
-- 5. Backup butonuna tikla
-- ============================================================


-- ============================================================
-- BOLUM 3: YENI VERI EKLE (Fark Yedek Icin)
-- ============================================================

-- 3.1 Yeni musteriler ekle
INSERT INTO customers (customer_id, company_name, contact_name, country)
VALUES ('YENI1', 'Yeni Sirket A', 'Ahmet Yilmaz', 'Turkey');

INSERT INTO customers (customer_id, company_name, contact_name, country)
VALUES ('YENI2', 'Yeni Sirket B', 'Fatma Kaya', 'Turkey');

-- 3.2 Yeni siparis ekle
INSERT INTO orders (order_id, customer_id, employee_id,
                    order_date, ship_country)
VALUES (999, 'YENI1', 1, CURRENT_DATE, 'Turkey');

-- 3.3 Eklenen verileri dogrula
SELECT customer_id, company_name, contact_name, country
FROM customers
WHERE customer_id IN ('YENI1', 'YENI2');

SELECT order_id, customer_id, order_date, ship_country
FROM orders
WHERE order_id = 999;


-- ============================================================
-- BOLUM 4: FARK YEDEKLEME (pgAdmin uzerinden)
-- ============================================================
-- pgAdmin adimlari:
-- 1. northwind veritabanina sag tikla
-- 2. Backup... sec
-- 3. Filename: northwind_fark_yedek.backup
-- 4. Format: Custom
-- 5. Backup butonuna tikla
-- ============================================================


-- ============================================================
-- BOLUM 5: FELAKET SENARYOSU
-- Kritik tablolari sil
-- ============================================================

-- 5.1 Kritik tablolari sil (felaketi simule et)
DROP TABLE order_details CASCADE;
DROP TABLE orders CASCADE;
DROP TABLE customers CASCADE;

-- 5.2 Silme islemi dogrula
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
-- customers, orders, order_details artik listede olmamali


-- ============================================================
-- BOLUM 6: GERI YUKLEME (pgAdmin uzerinden)
-- ============================================================
-- pgAdmin adimlari:
-- 1. northwind veritabanina sag tikla
-- 2. Restore... sec
-- 3. Format: Custom or tar
-- 4. Filename: northwind_fark_yedek.backup dosyasini sec
-- 5. Restore options sekmesine gec
-- 6. "Clean before restore" secenegini ac
-- 7. Restore butonuna tikla
-- ============================================================


-- ============================================================
-- BOLUM 7: GERI YUKLEME DOGRULAMASI
-- ============================================================

-- 7.1 Tablolar geri geldi mi?
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
-- 14 tablonun tamami geri gelmeli

-- 7.2 Kayit sayilarini karsilastir (yedek oncesiyle ayni olmali)
SELECT 'customers'    AS tablo, COUNT(*) AS kayit FROM customers
UNION ALL
SELECT 'orders',                COUNT(*) FROM orders
UNION ALL
SELECT 'order_details',         COUNT(*) FROM order_details
UNION ALL
SELECT 'products',              COUNT(*) FROM products
UNION ALL
SELECT 'employees',             COUNT(*) FROM employees;

-- 7.3 Fark yedekte eklenen yeni musteriler geri geldi mi?
SELECT customer_id, company_name, contact_name, country
FROM customers
WHERE customer_id IN ('YENI1', 'YENI2');
-- Her iki musteri de geri gelmeli

-- 7.4 Yeni siparis geri geldi mi?
SELECT order_id, customer_id, order_date, ship_country
FROM orders
WHERE order_id = 999;
-- 999 numarali siparis geri gelmeli


-- ============================================================
-- BOLUM 8: YEDEKLEME LOG SISTEMI
-- ============================================================

-- 8.1 Yedekleme log tablosu olustur
CREATE TABLE backup_log (
    id            SERIAL PRIMARY KEY,
    yedek_turu    TEXT,
    dosya_adi     TEXT,
    alinma_zamani TIMESTAMPTZ DEFAULT now(),
    aciklama      TEXT
);

-- 8.2 Yapilan yedekleri kayit altina al
INSERT INTO backup_log (yedek_turu, dosya_adi, aciklama)
VALUES (
    'TAM',
    'northwind_tam_yedek.backup',
    'Ilk tam yedek - tum veriler dahil'
);

INSERT INTO backup_log (yedek_turu, dosya_adi, aciklama)
VALUES (
    'FARK',
    'northwind_fark_yedek.backup',
    'Fark yedek - YENI1, YENI2 musterileri ve 999 siparisi eklendi'
);

-- 8.3 Log tablosunu goster
SELECT * FROM backup_log;
