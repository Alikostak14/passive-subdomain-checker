#!/bin/bash

# Renk tanımlamaları (ANSI Escape Codes)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# İkon tanımlamaları
ICON_200="🟢"
ICON_30X="🔵"
ICON_403="🟡"
ICON_404="🔴"
ICON_OTHER="⚪"

# 1. Gerekli araçlar kurulu mu kontrol et
if ! command -v jq &> /dev/null; then
    echo -e "${RED}[- ] Hata: 'jq' aracı sisteminizde kurulu değil.${NC}"
    echo "Lütfen kurun: sudo apt install jq"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}[- ] Hata: 'curl' aracı sisteminizde kurulu değil.${NC}"
    echo "Lütfen kurun: sudo apt install curl"
    exit 1
fi

# 2. Kullanıcıdan domain al
read -p "Lütfen hedef domaini girin (Örn: google.com): " TARGET_DOMAIN

if [ -z "$TARGET_DOMAIN" ]; then
    echo -e "${RED}[- ] Hata: Geçersiz domain girdiniz.${NC}"
    exit 1
fi

OUTPUT_FILE="${TARGET_DOMAIN}_passive_subdomains.txt"
> "$OUTPUT_FILE"

echo -e "\n[*] ${TARGET_DOMAIN} için Certificate Transparency (crt.sh) kayıtları sorgulanıyor..."

# 3. crt.sh API'sinden subdomainleri çek ve temizle
# - wildcard (*.) içerenleri temizler, benzersiz hale getirir (sort -u) ve hedef domaine ait olmayanları eler.
SUBDOMAINS=$(curl -s "https://crt.sh/?q=%.$TARGET_DOMAIN&output=json" | \
             jq -r '.[].name_value' | \
             tr ' ' '\n' | \
             sed 's/\*\.//g' | \
             grep -E "\.${TARGET_DOMAIN}$" | \
             sort -u)

# Bulunan subdomain sayısını kontrol et
SUB_COUNT=$(echo "$SUBDOMAINS" | wc -l)

if [ -z "$SUBDOMAINS" ] || [ "$SUB_COUNT" -eq 0 ]; then
    echo -e "${RED}[-] Hiçbir subdomain kaydı bulunamadı veya crt.sh yanıt vermedi.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Toplam ${SUB_COUNT} adet benzersiz subdomain tespit edildi!${NC}"
echo -e "[*] HTTP durum kodları sorgulanıyor...\n"

# 4. HTTP Durum Kodlarını Sorgula
echo "$SUBDOMAINS" | while read -r SUBDOMAIN; do
    [ -z "$SUBDOMAIN" ] && continue

    for PROTO in "https://" "http://"; do
        URL="${PROTO}${SUBDOMAIN}"
        
        # 5 saniye timeout ile sadece HTTP kodunu alıyoruz
        STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "$URL")
        
        if [ "$STATUS_CODE" -ne 000 ]; then
            case "$STATUS_CODE" in
                200)
                    echo -e "${GREEN}${ICON_200} [200] ${URL}${NC}"
                    echo "[200] ${URL}" >> "$OUTPUT_FILE"
                    ;;
                301|302)
                    echo -e "${BLUE}${ICON_30X} [${STATUS_CODE}] ${URL}${NC}"
                    echo "[${STATUS_CODE}] ${URL}" >> "$OUTPUT_FILE"
                    ;;
                403)
                    echo -e "${YELLOW}${ICON_403} [403] ${URL}${NC}"
                    echo "[403] ${URL}" >> "$OUTPUT_FILE"
                    ;;
                404)
                    echo -e "${RED}${ICON_404} [404] ${URL}${NC}"
                    echo "[404] ${URL}" >> "$OUTPUT_FILE"
                    ;;
                *)
                    echo -e "${ICON_OTHER} [${STATUS_CODE}] ${URL}"
                    echo "[${STATUS_CODE}] ${URL}" >> "$OUTPUT_FILE"
                    ;;
            esac
            break # Bir protokol yanıt verdiyse diğerini deneme
        fi
    done
done

echo -e "\n${GREEN}[+] Tarama tamamlandı! Sonuçlar '${OUTPUT_FILE}' dosyasına kaydedildi.${NC}"