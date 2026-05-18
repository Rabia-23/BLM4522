# Proje 1 — Veritabani Performans Optimizasyonu ve Izleme

**Platform:** PostgreSQL 14 + pgAdmin  
**Veritabani:** Northwind  
**SQL Dosyasi:** [proje1_performans.sql](./proje1_performans.sql)  
**Tarih:** 18.05.2026

---

## Proje Hakkinda

Bu projede Northwind veritabani uzerinde sorgu performans analizi yapilmis, index yonetimi uygulanmis ve veritabani istatistikleri izlenmistir. Tum islemler pgAdmin Query Tool uzerinden gerceklestirilmistir.

---

## Uygulanan Adimlar

### Adim 1 — Mevcut Durum Analizi
- Tablo boyutlari sorgulanmis, en buyuk tablolar tespit edilmistir (order_details, orders)
- Mevcut indexler listelenmis — yalnizca PRIMARY KEY indexleri mevcuttu

### Adim 2 — EXPLAIN ANALYZE ile Sorgu Analizi (Index Oncesi)
- customers WHERE country: Seq Scan, 80 satir elendi, 11 dondu
- orders WHERE order_date: Seq Scan, 422 satir elendi, 408 dondu
- orders WHERE ship_country: Seq Scan, 708 satir elendi, 122 dondu
- Uc sorguda da Seq Scan tespit edildi — index bulunmuyordu

### Adim 3 — Index Olusturma
- idx_customers_country, idx_orders_order_date, idx_orders_ship_country olusturuldu
- ship_country sorgusunda Bitmap Index Scan devreye girdi
- Kucuk tablolarda PostgreSQL Seq Scan'i tercih edebilir — bu maliyet bazli normal bir karar

### Adim 4 — Gereksiz Index Yonetimi
- idx_orders_freight ve idx_customers_fax olusturuldu (gosterim amacli)
- pg_stat_user_indexes ile kullanim istatistikleri sorgulandı
- Hic kullanilmayan indexler tespit edilerek silindi

### Adim 5 — JOIN Sorgusu Optimizasyonu
- orders + order_details JOIN sorgusu analiz edildi
- idx_orders_ship_country indexi devreye girdi
- PostgreSQL Hash Join yontemini kullandi

### Adim 6 — Veritabani Istatistikleri Izleme
- pg_stat_user_tables ile tablo saglik durumu izlendi
- Veri boyutu vs toplam boyut karsilastirildi — indexlerin kapladigi alan gosterildi

---

## Onemli Bulgular

|          Bulgu          |                         Aciklama                         |
|-------------------------|----------------------------------------------------------|
| Seq Scan tespit edildi  | Index olmayan sutunlarda PostgreSQL tum tabloyu tarıyor  |
| Bitmap Index Scan       | ship_country indexi JOIN sorgusunda devreye girdi        |
| Kucuk tablo davranisi   | PostgreSQL kucuk tablolarda index yerine Seq Scan tercih edebilir |
| Gereksiz index maliyeti | Kullanilmayan indexler disk alani tuketir, yazma performansini dusurur |