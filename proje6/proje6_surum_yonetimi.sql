-- ============================================================
-- BLM4522 - Proje 6: Veritabani Yukseltme ve Surum Yonetimi
-- Veritabani: Northwind (PostgreSQL 14)
-- Hazirlayan: Rabia Sevval Yasar
-- Tarih: 2026
-- ============================================================


-- ============================================================
-- BOLUM 1: MEVCUT DURUM BELGELEME (v1.0)
-- ============================================================

-- 1.1 PostgreSQL versiyonu
SELECT version();

-- 1.2 v1.0 sema yapisi
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('customers', 'orders', 'products')
ORDER BY table_name, ordinal_position;
-- v1.0'da:
--   customers: email yok, created_at yok
--   orders: status yok
--   products: unit_price real tipinde


-- ============================================================
-- BOLUM 2: DDL TRIGGER KURULUMU
-- Surum takibi icin her sema degisikligi otomatik loglanacak
-- ============================================================

-- 2.1 Surum log tablosu
CREATE TABLE schema_version_log (
    id            SERIAL PRIMARY KEY,
    versiyon      TEXT,
    degisiklik    TEXT,
    nesne_adi     TEXT,
    nesne_turu    TEXT,
    yapan         TEXT,
    tarih         TIMESTAMPTZ DEFAULT now()
);

-- 2.2 DDL trigger fonksiyonu
CREATE OR REPLACE FUNCTION log_ddl_changes()
RETURNS event_trigger AS $$
DECLARE
    obj record;
BEGIN
    FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        INSERT INTO schema_version_log
            (versiyon, degisiklik, nesne_adi, nesne_turu, yapan)
        VALUES
            ('v2.0', obj.command_tag,
             obj.object_identity,
             obj.object_type,
             current_user);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 2.3 Event trigger'i aktif et
CREATE EVENT TRIGGER ddl_logger
    ON ddl_command_end
    EXECUTE FUNCTION log_ddl_changes();

-- 2.4 Trigger kurulumunu dogrula
SELECT evtname, evtevent, evtenabled
FROM pg_event_trigger;
-- ddl_logger | ddl_command_end | O (O = enabled)


-- ============================================================
-- BOLUM 3: v2.0 YUKSELTME PLANI
-- ============================================================

-- Degisiklik 1: customers tablosuna yeni sutunlar
ALTER TABLE customers ADD COLUMN email VARCHAR(100);
ALTER TABLE customers ADD COLUMN created_at TIMESTAMPTZ DEFAULT now();

-- Degisiklik 2: unit_price tipini yukselt (real -> numeric)
-- Neden? Numeric para birimi icin cok daha uygun --
-- ondalik hassasiyeti garanti altina alir
ALTER TABLE products ALTER COLUMN unit_price TYPE NUMERIC(10,2);

-- Degisiklik 3: orders tablosuna status sutunu
ALTER TABLE orders ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
-- Mevcut 830 siparis otomatik olarak 'pending' statusune alindi

-- Degisiklik 4: Versiyon takip tablosu
CREATE TABLE db_version (
    id             SERIAL PRIMARY KEY,
    versiyon       TEXT NOT NULL,
    aciklama       TEXT,
    yukleme_tarihi TIMESTAMPTZ DEFAULT now()
);

INSERT INTO db_version (versiyon, aciklama)
VALUES (
    'v2.0',
    'Email ve created_at customers icin eklendi,
     unit_price numeric yapildi, orders status eklendi'
);

-- DDL trigger log kontrol
SELECT versiyon, degisiklik, nesne_adi, nesne_turu, tarih
FROM schema_version_log
ORDER BY id;
-- 8 degisiklik otomatik loglanmis olmali


-- ============================================================
-- BOLUM 4: YUKSELTME DOGRULAMASI
-- ============================================================

-- customers yeni sutunlar
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'customers'
  AND column_name IN ('email', 'created_at');

-- orders status sutunu
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'orders'
  AND column_name = 'status';

-- products unit_price tipi
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'products'
  AND column_name = 'unit_price';

-- Versiyon tablosu
SELECT * FROM db_version;


-- ============================================================
-- BOLUM 5: GERI DONUS PLANI (Rollback to v1.0)
-- ============================================================

-- Geri donus 1: yeni sutunlari kaldir
ALTER TABLE customers DROP COLUMN email;
ALTER TABLE customers DROP COLUMN created_at;

-- Geri donus 2: unit_price eski tipine dondur
ALTER TABLE products ALTER COLUMN unit_price TYPE real;

-- Geri donus 3: status sutununu kaldir
ALTER TABLE orders DROP COLUMN status;

-- Geri donus 4: versiyon tablosunu kaldir
DROP TABLE db_version;

-- Geri donus dogrulama
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'customers'
ORDER BY ordinal_position;
-- 11 sutun olmali, email ve created_at gitmis olmali

-- Geri donusu logla
INSERT INTO schema_version_log
    (versiyon, degisiklik, nesne_adi, nesne_turu, yapan)
VALUES
    ('v1.0', 'ROLLBACK', 'northwind', 'database', current_user);

-- Tam log gecmisi
SELECT versiyon, degisiklik, nesne_adi, tarih
FROM schema_version_log
ORDER BY id;
-- v2.0 yukseltme adimlari + v1.0 rollback kaydı gorunmeli
