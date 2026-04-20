# Proje 5 — Veri Temizleme ve ETL Surecleri Tasarimi

**Platform:** PostgreSQL 14  
**Veritabani:** Chinook  
**SQL Dosyasi:** [proje5_etl.sql](./proje5_etl.sql)

---

## Proje Hakkinda

Bu projede Chinook veritabani internet uzerinden indirilmis ve customer tablosunun tum 12 sutunu sistematik sorgularla analiz edilmistir. Kasitli hata eklenmemistir — veritabaninin orijinal halindeki gercek veri kalite sorunlari kesfedilip temizlenmistir.

---

## Extract — Tespit Edilen Sorunlar

| Sutun | Sorunlu Kayit | Karar |
|---|---|---|
| phone | 1 | Duzeltildi: 'Bilgi Yok' |
| company | 49 | Siniflandirildi: 'Bireysel Musteri' |
| state | 29 | Standartlastirildi: 'N/A' (Avrupa ulkeleri) |
| postal_code | 4 | Isaretlendi: 'Bilinmiyor' |
| fax | 47 | Mudahale edilmedi (opsiyonel alan) |
| Diger 7 sutun | 0 | Temiz |

---

## Transform — Temizleme Kararlari

- **phone NULL:** 'Bilgi Yok' ile isaretlendi. Silmek yerine isaretleme tercih edildi.
- **company NULL:** 'Bireysel Musteri' olarak siniflandirildi. Bireysel musteri olabilir.
- **state bos:** Sadece Avrupa ulkeleri 'N/A' yapildi. USA/Canada/Brazil/Australia'da eyalet sistemi var, oradaki bosluk gercek eksiklik sayilir.
- **postal_code bos:** 'Bilinmiyor' ile isaretlendi.
- **fax NULL:** Mudahale edilmedi. Fax opsiyonel iletisim kanali, eksikligi hata degil.

---

## Load — Kalite Raporu

| Metrik | Deger |
|---|---|
| Ham veri | 59 satir |
| Temiz veri | 54 satir |
| Telefon duzeltilen | 1 |
| Sirket siniflandirilan | 49 |
| State standartlastirilan | 29 |
| Posta kodu isaretlenen | 4 |
| Fax yok (opsiyonel) | 47 |

---

## Kurulum

```bash
psql postgres -c "CREATE DATABASE chinook;"
psql -d chinook -f Chinook_PostgreSql.sql
psql -d chinook -f proje5_etl.sql
```
