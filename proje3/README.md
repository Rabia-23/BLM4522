# Proje 3 — Veritabani Guvenligi ve Erisim Kontrolu

**Platform:** PostgreSQL 14  
**Veritabani:** Northwind  
**SQL Dosyasi:** [proje3_guvenlik.sql](./proje3_guvenlik.sql)

---

## Proje Hakkinda

Bu projede Northwind veritabani internet uzerinden indirilmis ve mevcut guvenlik durumu sorgularla analiz edilmistir. Kasitli hata eklenmemistir — veritabaninin orijinal halindeki gercek guvenlik eksiklikleri tespit edilerek giderilmistir.

---

## Tespit Edilen Aciklar

| Acik | Tespit Yontemi | Risk |
|---|---|---|
| Erisim kontrolu yok | role_table_grants — 0 satir | KRITIK |
| Hassas veri sifrelenmemis | employees tablosu incelemesi | YUKSEK |
| Aktivite izleme yok | pg_policies — 0 satir | YUKSEK |
| RLS politikasi yok | pg_policies — 0 satir | YUKSEK |

---

## Uygulanan Guvenlik Katmanlari

### Katman 1 — Rol Tabanli Erisim Kontrolu (RBAC)
- 3 rol: readonly_role, dataentry_role, admin_role
- 3 kullanici: analyst, dataentry, dbadmin
- Test: analyst INSERT yapamiyor (permission denied)

### Katman 2 — Veri Sifreleme
- pgcrypto eklentisi ile AES-128 sifreleme
- employees.home_phone sifreli olarak saklanmaktadir
- Dogru anahtar olmadan veri okunamaz

### Katman 3 — SQL Injection Korunmasi
- Savunmasiz sorgu: tum tablo dokuld
- Parametreli sorgu: saldiri 0 satir dondurudu

### Katman 4 — Audit Log
- Trigger tabanli sistem
- INSERT, UPDATE, DELETE islemleri kayit altinda
- Eski ve yeni deger karsilastirmali log

### Katman 5 — Row Level Security (RLS)
- orders tablosuna uygulanmistir
- us_manager: sadece USA siparisleri (122)
- de_manager: sadece Germany siparisleri (122)
- br_manager: sadece Brazil siparisleri (83)

---

## Kurulum

```bash
psql postgres -c "CREATE DATABASE northwind;"
psql -d northwind -f northwind.sql
psql -d northwind -f proje3_guvenlik.sql
```
