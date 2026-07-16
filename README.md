# 🔍 Passive Subdomain Checker

Passive Subdomain Checker, hedef web sitelerine doğrudan istek göndermeden ve ağ üzerinde gürültü yaratmadan pasif keşif yapmanızı sağlayan hafif, hızlı ve etkili bir siber güvenlik aracıdır. 

Sertifika Şeffaflığı (Certificate Transparency - CT) loglarını kullanarak alt alan adlarını saniyeler içinde tespit eder ve ardından aktif olanları belirlediğiniz HTTP durum kodlarına göre renkli emojilerle listeler.

---

## 🚀 Özellikler

* **Tamamen Pasif Keşif:** Hedef sunucuya yüzlerce DNS sorgusu göndermez. Verileri doğrudan halka açık `crt.sh` loglarından çeker.
* **Akıllı Durum Kodu Analizi:** Tespit edilen her subdomain için sırasıyla `HTTPS` ve `HTTP` protokollerini test eder.
* **Görsel Bildirimler:** Durum kodlarını hızlıca analiz edebilmeniz için renkli emojilerle çıktı üretir:
  * 🟢 **200 OK**
  * 🔵 **301/302 Redirect**
  * 🟡 **403 Forbidden**
  * 🔴 **404 Not Found**
  * ⚪ **Diğer Durum Kodları**
* **Otomatik Kayıt:** Bulunan tüm aktif subdomainleri otomatik olarak düzgün bir formatta `<hedef_domain>_passive_subdomains.txt` dosyasına kaydeder.

---

## 📋 Gereksinimler

Aracın çalışması için sisteminizde `curl` ve `jq` araçlarının kurulu olması gerekir. Kurmak için:

```bash
sudo apt update && sudo apt install jq curl -y



Bu araç sadece eğitim ve güvenlik testi (Bug Bounty, Sızma Testleri) amaçlı geliştirilmiştir. Kullanıcıların gerçekleştirdiği eylemlerin sorumluluğu tamamen kendilerine aittir.
