-- ============================================================
-- BLM4522 - Proje 5: Veri Temizleme ve ETL Surecleri Tasarimi
-- Veritabani: Chinook (PostgreSQL)
-- Hazirlayan: Rabia Sevval Yasar
-- Tarih: Nisan 2026
-- ============================================================


-- ============================================================
-- BOLUM 1: EXTRACT - Veri Kalitesi Kesfi
-- Tum sutunlarin sistematik taranmasi
-- ============================================================

-- 1.1 Tum sutunlari tek sorguda tara
SELECT
  COUNT(*) AS toplam,
  COUNT(*) FILTER (WHERE first_name IS NULL
                       OR first_name = '')   AS bos_isim,
  COUNT(*) FILTER (WHERE last_name IS NULL
                       OR last_name = '')    AS bos_soyisim,
  COUNT(*) FILTER (WHERE email IS NULL)      AS null_email,
  COUNT(*) FILTER (WHERE phone IS NULL)      AS null_phone,
  COUNT(*) FILTER (WHERE fax IS NULL)        AS null_fax,
  COUNT(*) FILTER (WHERE company IS NULL)    AS null_company,
  COUNT(*) FILTER (WHERE address IS NULL
                       OR address = '')      AS bos_adres,
  COUNT(*) FILTER (WHERE city IS NULL
                       OR city = '')         AS bos_sehir,
  COUNT(*) FILTER (WHERE country IS NULL
                       OR country = '')      AS bos_ulke,
  COUNT(*) FILTER (WHERE state IS NULL
                       OR state = '')        AS bos_state,
  COUNT(*) FILTER (WHERE postal_code IS NULL
                       OR postal_code = '')  AS bos_posta_kodu
FROM customer;
-- Beklenen bulgular:
-- null_phone: 1, null_fax: 47, null_company: 49
-- bos_state: 29, bos_posta_kodu: 4
-- Diger alanlar: 0 (temiz)

-- 1.2 NULL telefon detayi
SELECT customer_id, first_name, last_name, country, phone
FROM customer
WHERE phone IS NULL;
-- 1 musteri telefon bilgisi olmadan kayitli

-- 1.3 State boslugunun nedeni: hangi ulkeler?
SELECT country, COUNT(*) as sayi
FROM customer
WHERE state IS NULL OR state = ''
GROUP BY country
ORDER BY sayi DESC;
-- Fransa, Almanya, Ingiltere gibi Avrupa ulkeleri
-- Avrupa'da eyalet sistemi yok -- cografi gerceklik

-- 1.4 Posta kodu eksik musteriler
SELECT customer_id, first_name, last_name, country, postal_code
FROM customer
WHERE postal_code IS NULL OR postal_code = '';
-- Portekiz (2), Irlanda (1), Sili (1)

-- 1.5 Telefon format tutarliligi
SELECT
  COUNT(*) FILTER (WHERE phone LIKE '+%')       AS uluslararasi_format,
  COUNT(*) FILTER (WHERE phone NOT LIKE '+%'
                       AND phone IS NOT NULL)   AS yerel_format,
  COUNT(*) FILTER (WHERE phone IS NULL)         AS bos
FROM customer;
-- Tum telefonlar + ile basliyor -- format tutarli

-- 1.6 Fax dagilim analizi
SELECT country,
  COUNT(*)              AS toplam,
  COUNT(fax)            AS fax_olan,
  COUNT(*) - COUNT(fax) AS fax_olmayan
FROM customer
GROUP BY country
HAVING COUNT(*) - COUNT(fax) > 0
ORDER BY fax_olmayan DESC;
-- Fax opsiyonel alan -- mudahale edilmeyecek


-- ============================================================
-- BOLUM 2: TRANSFORM - Temizleme ve Standartlastirma
-- Her sorun icin farkli strateji
-- ============================================================

-- 2.1 NULL telefonu isaretله
-- Silmek yerine isaretliyoruz: diger bilgiler gecerli olabilir
UPDATE customer
SET phone = 'Bilgi Yok'
WHERE phone IS NULL;
-- Sonuc: UPDATE 1

-- 2.2 Eksik sirket bilgisini siniflandir
-- Bireysel musteri olabilir -- silmek yerine siniflandiriyoruz
UPDATE customer
SET company = 'Bireysel Musteri'
WHERE company IS NULL;
-- Sonuc: UPDATE 49

-- 2.3 Avrupa ulkelerinde state alanini standartlastir
-- NOT: USA, Canada, Brazil, Australia'da eyalet sistemi VAR
--      Bu ulkelerdeki state boslugu gercek eksiklik sayilir
--      Diger ulkelerde (Avrupa vb.) eyalet sistemi YOK
--      Bu yuzden sadece bu 4 ulke DISINDAKILERI N/A yapiyoruz
UPDATE customer
SET state = 'N/A'
WHERE (state IS NULL OR state = '')
  AND country NOT IN ('USA', 'Canada', 'Brazil', 'Australia');
-- Sonuc: UPDATE 29

-- 2.4 Eksik posta kodlarini isaretله
UPDATE customer
SET postal_code = 'Bilinmiyor'
WHERE postal_code IS NULL OR postal_code = '';
-- Sonuc: UPDATE 4

-- 2.5 Fax alani -- mudahale edilmiyor
-- Karar: Fax opsiyonel iletisim kanali
--        NULL olmasi hata degil, bu karar raporda belgelendi
SELECT
  COUNT(*) FILTER (WHERE fax IS NOT NULL) AS fax_mevcut,
  COUNT(*) FILTER (WHERE fax IS NULL)     AS fax_yok
FROM customer;


-- ============================================================
-- BOLUM 3: LOAD - Temiz Tabloyu Olusturma
-- ============================================================

-- 3.1 Temiz tabloyu olustur
-- NOT: company ve state icin yapilan islem "doldurma"ydi
--      Bu musteriler hala gecerli kayit -- temiz tabloya giriyor
--      Telefon ve posta kodu ise gercek islem engeli:
--      - Telefonu olmayana ulasamazsin
--      - Posta kodu olmayana kargo gonderemezsin
--      Bu yuzden sadece bu ikisi filtre olarak kullaniliyor

-- Secenek B (tercih edilen): sadece ulasılabilir musteriler
CREATE TABLE customer_clean AS
SELECT * FROM customer
WHERE phone != 'Bilgi Yok'
  AND postal_code != 'Bilinmiyor';

-- Secenek A (alternatif): tum musteriler
-- CREATE TABLE customer_clean AS SELECT * FROM customer;

-- 3.2 Once/sonra kalite raporu
SELECT 'Ham veri (toplam)'         AS aciklama, COUNT(*) AS sayi FROM customer
UNION ALL
SELECT 'Temiz veri',                COUNT(*) FROM customer_clean
UNION ALL
SELECT 'Telefon duzeltilen',        COUNT(*) FROM customer
  WHERE phone = 'Bilgi Yok'
UNION ALL
SELECT 'Sirket siniflandirilan',    COUNT(*) FROM customer
  WHERE company = 'Bireysel Musteri'
UNION ALL
SELECT 'State standartlastirilan',  COUNT(*) FROM customer
  WHERE state = 'N/A'
UNION ALL
SELECT 'Posta kodu isaretlenen',    COUNT(*) FROM customer
  WHERE postal_code = 'Bilinmiyor'
UNION ALL
SELECT 'Fax yok (opsiyonel)',       COUNT(*) FROM customer
  WHERE fax IS NULL;

-- 3.3 Temiz tablo dogrulamasi
SELECT
  COUNT(*)          AS toplam,
  COUNT(phone)      AS telefon_dolu,
  COUNT(company)    AS sirket_dolu,
  COUNT(state)      AS state_dolu,
  COUNT(postal_code) AS posta_dolu
FROM customer_clean;
