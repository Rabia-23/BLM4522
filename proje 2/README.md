# Proje 2 — Veritabani Yedekleme ve Felaketten Kurtarma

**Platform:** PostgreSQL 14 + pgAdmin  
**Veritabani:** Northwind  
**SQL Dosyasi:** [proje2_yedekleme.sql](./proje2_yedekleme.sql)

---

## Proje Hakkinda

Bu projede Northwind veritabani uzerinde tam yedekleme, fark yedekleme ve felaketten kurtarma sureci uygulanmistir. Yedekleme islemleri pgAdmin arayuzu uzerinden, veri dogrulama adimlari SQL sorguluariyla gerceklestirilmistir.

---

## Uygulanan Adimlar

### Adim 1 — Tam Yedekleme
- pgAdmin → northwind → Backup
- Format: Custom
- Dosya: northwind_tam_yedek.backup

### Adim 2 — Yeni Veri Ekleme
- 2 yeni musteri eklendi (YENI1, YENI2)
- 1 yeni siparis eklendi (order_id: 999)

### Adim 3 — Fark Yedekleme
- pgAdmin → northwind → Backup
- Format: Custom
- Dosya: northwind_fark_yedek.backup

### Adim 4 — Felaket Senaryosu
- customers, orders, order_details tablolari silindi
- Veri kaybi dogrulandi

### Adim 5 — Geri Yukleme
- pgAdmin → northwind → Restore
- Kaynak: northwind_fark_yedek.backup
- Clean before restore: Acik

### Adim 6 — Dogrulama
- 14 tablo geri yuklendi
- Kayit sayilari yedek oncesiyle eslesti
- YENI1, YENI2 musterileri ve 999 siparisi geri geldi

---

## Yedekleme Stratejisi

| Yedek Turu |            Dosya            |              Icerik              |
|------------|-----------------------------|----------------------------------|
| Tam Yedek  | northwind_tam_yedek.backup  | Tum veriler                      |
| Fark Yedek | northwind_fark_yedek.backup | Tam yedek + yeni eklenen veriler |

---

## Onemli Not

Felaketten kurtarmada fark yedek kullanilmistir. Tam yedek kullanilsaydi sonradan eklenen YENI1, YENI2 musterileri ve 999 numarali siparis kaybolurdu. Bu, fark yedeklemenin onemini gostermektedir.
