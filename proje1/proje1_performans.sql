-- ============================================================
-- BLM4522 - Proje 1: Veritabani Performans Optimizasyonu
-- Veritabani: Northwind (PostgreSQL)
-- Hazirlayan: Rabia Sevval Yasar
-- Tarih: 18.05.2026
-- ============================================================


-- ============================================================
-- BOLUM 1: MEVCUT DURUM ANALIZI
-- ============================================================

-- 1.1 Tablo boyutlari
SELECT
  table_name,
  pg_size_pretty(
    pg_total_relation_size(quote_ident(table_name))
  ) AS boyut
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;

-- 1.2 Mevcut indexler
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;
-- Sadece pk_ ile baslayan PRIMARY KEY indexleri var
-- country, order_date, ship_country gibi sutunlarda index yok


-- ============================================================
-- BOLUM 2: EXPLAIN ANALYZE - INDEX ONCESI SORGU ANALIZI
-- ============================================================

-- 2.1 Musteri ulkesine gore arama (Seq Scan bekleniyor)
EXPLAIN ANALYZE
SELECT * FROM customers
WHERE country = 'Germany';
-- Sonuc: Seq Scan, 80 satir filtrelendi, 11 dondu, ~0.064ms

-- 2.2 Siparis tarihine gore arama (Seq Scan bekleniyor)
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE order_date BETWEEN '1997-01-01' AND '1997-12-31';
-- Sonuc: Seq Scan, 422 satir filtrelendi, 408 dondu, ~0.204ms

-- 2.3 Gonderim ulkesine gore arama (Seq Scan bekleniyor)
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE ship_country = 'Germany';
-- Sonuc: Seq Scan, 708 satir filtrelendi, 122 dondu, ~0.220ms


-- ============================================================
-- BOLUM 3: INDEX OLUSTURMA
-- ============================================================

-- 3.1 Performans indexleri ekle
CREATE INDEX idx_customers_country
    ON customers(country);

CREATE INDEX idx_orders_order_date
    ON orders(order_date);

CREATE INDEX idx_orders_ship_country
    ON orders(ship_country);

-- 3.2 Index sonrasi ayni sorgulari tekrar calistir
EXPLAIN ANALYZE
SELECT * FROM customers
WHERE country = 'Germany';
-- Not: Tablo kucuk oldugu icin PostgreSQL Seq Scan tercih edebilir

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE order_date BETWEEN '1997-01-01' AND '1997-12-31';

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE ship_country = 'Germany';
-- Sonuc: Bitmap Index Scan devreye girdi, ~0.151ms


-- ============================================================
-- BOLUM 4: GEREKSIZ INDEX YONETIMI
-- ============================================================

-- 4.1 Gereksiz indexler olustur (gosterim amacli)
CREATE INDEX idx_orders_freight   ON orders(freight);
CREATE INDEX idx_customers_fax    ON customers(fax);

-- 4.2 Hangi indexler kullaniliyor, hangisi kullanilmiyor?
SELECT
  pg_stat_user_indexes.indexrelname  AS index_adi,
  pg_stat_user_indexes.relname       AS tablo,
  pg_stat_user_indexes.idx_scan      AS kac_kez_kullanildi,
FROM pg_stat_user_indexes
JOIN pg_stat_user_tables
  ON pg_stat_user_indexes.relid = pg_stat_user_tables.relid
ORDER BY pg_stat_user_indexes.idx_scan ASC;
-- idx_orders_ship_country: 2 kez kullanildi (aktif)
-- idx_orders_freight, idx_customers_fax, idx_customers_country, idx_orders_order_date: 0 kez (gereksiz)

-- 4.3 Gereksiz indexleri sil
DROP INDEX idx_orders_freight;
DROP INDEX idx_customers_fax;
DROP INDEX idx_customers_country;
DROP INDEX idx_orders_order_date;


-- ============================================================
-- BOLUM 5: JOIN SORGUSU OPTIMIZASYONU
-- ============================================================

-- 5.1 Agir JOIN sorgusu - index devreye giriyor
EXPLAIN ANALYZE
SELECT o.order_id, od.product_id,
       od.unit_price, od.quantity,
       od.unit_price * od.quantity AS toplam
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
WHERE o.ship_country = 'Germany'
ORDER BY toplam DESC;
-- Sonuc: idx_orders_ship_country devreye girdi, ~0.792ms


-- ============================================================
-- BOLUM 6: VERITABANI ISTATISTIKLERI IZLEME
-- ============================================================

-- 6.1 Tablo saglik istatistikleri
SELECT
   relname          AS tablo,
   n_live_tup       AS aktif_satir,
   n_dead_tup       AS silinmis_satir,
   seq_scan         AS tam_tablo_tarama,
   idx_scan         AS index_tarama
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

-- 6.2 Veri boyutu vs toplam boyut (index boyutlari dahil)
SELECT
   relname AS tablo,
   pg_size_pretty(
      pg_relation_size(quote_ident(relname)))       AS veri_boyutu,
   pg_size_pretty(
      pg_total_relation_size(quote_ident(relname))) AS toplam_boyut
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(quote_ident(relname)) DESC;
-- orders: veri 112kB, toplam 192kB -- fark index boyutu
-- order_details: veri 96kB, toplam 192kB -- fark index boyutu
-- customers: veri 16kB, toplam 56kB -- indexler cok yer kaplıyor