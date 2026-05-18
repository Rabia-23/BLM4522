# BLM4522 - Ag Tabanli Paralel Dagitim Sistemleri

**Ogrenci:** Rabia Sevval Yasar  
**Donem:** 2025-2026 Bahar  
**Platform:** PostgreSQL 14 (Homebrew, macOS M2)

---

## Projeler

### Proje 1 — Veritabani Performans Optimizasyonu ve Izleme
- **Veritabani:** Northwind
- **Tarih:** 18.05.2026
- **Klasor:** [proje1/](./proje1/)
- **Konu:** EXPLAIN ANALYZE ile sorgu analizi yapilmis, index yonetimi uygulanmis ve veritabani istatistikleri izlenmistir.
- **Icerik:** EXPLAIN ANALYZE, Seq Scan vs Index Scan, index olusturma/silme, JOIN optimizasyonu, pg_stat izleme
- **Video:** https://drive.google.com/file/d/1mO2AKCySgy3Yu2OqvDSRQC_74e0qKn0C/view?usp=sharing

### Proje 2 — Veritabani Yedekleme ve Felaketten Kurtarma
- **Veritabani:** Northwind
- **Tarih:** 14.05.2026
- **Klasor:** [proje2/](./proje2/)
- **Konu:** Tam yedekleme, fark yedekleme ve felaketten kurtarma sureci uygulanmistir.
- **Icerik:** Tam yedek, fark yedek, felaket senaryosu (CASCADE DROP), geri yukleme, yedekleme log sistemi
- **Video:** https://drive.google.com/file/d/1tTe-ut1kaFR6U8i4JEYbPskB2oS5J9Ui/view?usp=sharing

### Proje 3 — Veritabani Guvenligi ve Erisim Kontrolu
- **Veritabani:** Northwind
- **Tarih:** 21.04.2026
- **Klasor:** [proje3/](./proje3/)
- **Konu:** Northwind veritabaninin gercek guvenlik aciklari tespit edilmis ve bes katmanli guvenlik sistemi kurulmustur.
- **Icerik:** RBAC, AES sifreleme, SQL Injection korunmasi, Audit Log, Row Level Security
- **Video:** https://drive.google.com/file/d/13wwYKh7KJKctdCbaVmhEwAsI-aKoJqGc/view?usp=sharing

### Proje 5 — Veri Temizleme ve ETL Surecleri Tasarimi
- **Veritabani:** Chinook
- **Tarih:** 21.04.2026
- **Klasor:** [proje5/](./proje5/)
- **Konu:** Chinook veritabanindaki gercek veri kalite sorunlari kesfedilmis ve ETL sureci uygulanmistir.
- **Icerik:** Extract (12 sutun tarama), Transform (temizleme kararlari), Load (temiz tablo)
- **Video:** https://drive.google.com/file/d/1-Sv-X1e-5cK531xPRfFNWNRA7wdu91QI/view?usp=sharing

---

## Notlar

- Proje 3 ve Proje 5'te kasitli hata eklenmemistir — veritabanlarinin orijinal halindeki gercek sorunlar tespit edilip cozulmustur.
- Proje 2'de felaket senaryosu CASCADE DROP ile simule edilmistir.
- Proje 2 yedekleme islemleri pgAdmin arayuzu uzerinden gerceklestirilmistir.