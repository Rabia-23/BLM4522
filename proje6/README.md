# Proje 6 — Veritabani Yukseltme ve Surum Yonetimi

**Platform:** PostgreSQL 14 + pgAdmin  
**Veritabani:** Northwind  
**SQL Dosyasi:** [proje6_surum_yonetimi.sql](./proje6_surum_yonetimi.sql)  
**Tarih:** 22.05.2026

---

## Proje Hakkinda

Bu projede Northwind veritabani v1.0'dan v2.0'a yukseltilemis, tum sema degisiklikleri DDL event trigger ile otomatik olarak izlenmis ve geri donus plani test edilmistir. Tum islemler pgAdmin Query Tool uzerinden SQL komutlariyla gerceklestirilmistir.

---

## Uygulanan Adimlar

### Adim 1 — v1.0 Mevcut Durum Belgeleme
- PostgreSQL versiyonu sorgulanmistir (14.19)
- customers, orders, products tablolarinin v1.0 sema yapisi kayit altina alinmistir
- v2.0'da degisecek alanlar tespit edilmistir

### Adim 2 — DDL Trigger Kurulumu
- schema_version_log tablosu olusturuldu
- log_ddl_changes() event trigger fonksiyonu yazildi
- ddl_logger event trigger'i ddl_command_end olayina baglanarak aktive edildi
- Bundan sonra yapilan her ALTER TABLE ve CREATE TABLE otomatik loglanmaktadir

### Adim 3 — v2.0 Yukseltme Plani (4 Degisiklik)
- customers tablosuna email (VARCHAR) ve created_at (TIMESTAMPTZ) sutunlari eklendi
- products tablosunda unit_price tipi real'den NUMERIC(10,2)'ye yukseltildi
- orders tablosuna status (VARCHAR, DEFAULT 'pending') sutunu eklendi
- db_version tablosu olusturularak v2.0 kaydı eklendi

### Adim 4 — Yukseltme Dogrulamasi
- Yeni sutunlarin varligi information_schema.columns ile dogrulandi
- unit_price veri tipinin degistigi dogrulandi
- DDL log tablosunda 8 degisikligin otomatik loglandigi goruldu

### Adim 5 — Geri Donus Plani (Rollback to v1.0)
- email ve created_at sutunlari customers'dan kaldirildi
- unit_price tipi real'e geri donusu
- status sutunu orders'dan kaldirildi
- db_version tablosu silindi
- customers tablosunun orijinal 11 sutununa dondugu dogrulandi
- Rollback kaydi schema_version_log tablosuna elle eklendi

---

## Onemli Bulgular

|           Konu           |                           Aciklama                           |
|--------------------------|--------------------------------------------------------------|
| DDL Trigger              | Her ALTER TABLE ve CREATE TABLE otomatik loglanmistir — elle kayit gerekmez |
| unit_price tip degisimi  | real tipi para biriminde yuvarlama hatasi yapabilir — numeric(10,2) daha guvenilir |
| Rollback                 | Tum v2.0 degisiklikleri basariyla geri alindi, v1.0'a donuldu |
| Log gecmisi              | v2.0 yukseltme adimlari ve v1.0 rollback kaydinin tamami schema_version_log'da gorunuyor |

---

## DDL Trigger Hakkinda

DDL (Data Definition Language) trigger, CREATE TABLE, ALTER TABLE, DROP TABLE gibi yapisal degisiklikler yapildiginda otomatik tetiklenir. Bu sayede manuel takip gerekmeden tum degisiklikler tarih, kullanici ve nesne bilgisiyle birlikte kayit altina alinir.