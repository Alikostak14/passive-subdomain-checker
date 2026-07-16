# 🔍 Advanced Passive Subdomain Finder & Checker

Gelişmiş, çoklu kaynak desteğine sahip ve yüksek performanslı bir pasif subdomain keşif aracıdır. Hedef sistem üzerinde gürültü yaratmadan (DNS kaba kuvvet saldırısı yapmadan) saniyeler içinde binlerce potansiyel subdomain toplar, aktifliklerini kontrol eder ve durum kodlarına göre sınıflandırır.

---

## 🚀 Öne Çıkan Özellikler

* **Çoklu Pasif Kaynak Desteği:** Tek bir istek yerine subdomain verilerini 5 farklı güvenilir pasif kaynaktan toplar ve birleştirir:
  * `crt.sh` (Sertifika Şeffaflığı Logları)
  * `jldc.me` (Anubis API)
  * `api.hackertarget.com` (HackerTarget Veritabanı)
  * `otx.alienvault.com` (AlienVault Passive DNS)
  * `web.archive.org` (Wayback Machine CDX API)
* **⚡ Akıllı DNS Ön-Filtreleme (Yeni):** Bulunan eski veya ölü subdomain kayıtlarına `curl` istekleri gönderip timeout sürelerini beklemek yerine, önce yerleşik `getent` mekanizması ile hızlıca DNS doğrulaması yapar. IP adresi çözülemeyen adresleri doğrudan eleyerek muazzam bir hız artışı sağlar.
* **⏩ Paralel İş Parçacığı (Multithreading):** `xargs -P` mimarisi sayesinde belirlediğiniz thread sayısıyla (varsayılan: 15) canlılık kontrollerini tamamen eş zamanlı yürütür.
* **🎨 Görsel ve Temiz Çıktı:** Terminal ekranında durum kodlarını emojilerle (`✅`, `↪️ `, `⚠️ `, `❌`) renklendirirken, sonuçları düzenli bir şekilde log dosyasına kaydeder.

---
Bu araç sadece siber güvenlik araştırmaları, Bug Bounty süreçleri ve yetkili sızma testleri amacıyla geliştirilmiştir. Kullanımdan doğabilecek tüm sorumluluk son kullanıcıya aittir.



## 📋 Gereksinimler

Aracın çalışabilmesi için Linux sisteminizde `curl` ve `jq` paketlerinin kurulu olması yeterlidir:

```bash
sudo apt update && sudo apt install jq curl -y
