#!/usr/bin/env bash
#
# subdomain_finder.sh
# ---------------------------------------------------------------
# Verilen bir domain için crt.sh (Certificate Transparency logları)
# üzerinden subdomain'leri toplar, her birinin ayakta olup olmadığını
# kontrol eder, HTTP durum kodlarını renkli olarak ekrana basar ve
# sonuçları bir dosyaya kaydeder.
#
# Kullanım:
#   ./subdomain_finder.sh example.com
#   ./subdomain_finder.sh example.com -o cikti.txt -t 20
#
# ---------------------------------------------------------------

set -uo pipefail

# ---------------------- Renk tanımları ----------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ---------------------- Varsayılanlar ----------------------
DOMAIN=""
OUTFILE=""
THREADS=15          # aynı anda kaç subdomain kontrol edilecek
TIMEOUT=6           # her istek için saniye cinsinden timeout

usage() {
    echo "Kullanım: $0 <domain> [-o cikti_dosyasi] [-t thread_sayisi]"
    echo "  Örnek : $0 example.com"
    echo "  Örnek : $0 example.com -o sonuc.txt -t 30"
    exit 1
}

# ---------------------- Argümanları işle ----------------------
if [[ $# -lt 1 ]]; then
    usage
fi

DOMAIN="$1"
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTFILE="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Bilinmeyen parametre: $1"
            usage
            ;;
    esac
done

# domain doğrulaması (basit)
if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}Hata: Domain belirtmelisiniz.${NC}"
    usage
fi

# Gerekli araçlar kontrolü
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}Hata: '$cmd' kurulu değil. Lütfen kurun (örn: sudo apt install $cmd -y)${NC}"
        exit 1
    fi
done

if [[ -z "$OUTFILE" ]]; then
    TS=$(date +"%Y%m%d_%H%M%S")
    OUTFILE="${DOMAIN}_subdomains_${TS}.txt"
fi

TMPDIR=$(mktemp -d)
RAW_LIST="$TMPDIR/raw_list.txt"
ALIVE_LIST="$TMPDIR/alive_list.txt"
trap 'rm -rf "$TMPDIR"' EXIT

echo -e "${CYAN}${BOLD}[*] Hedef domain:${NC} $DOMAIN"
echo -e "${CYAN}[*] Birden fazla kaynaktan subdomainler toplanıyor...${NC}"
echo ""

CRT_LIST="$TMPDIR/crt.txt"
JLDC_LIST="$TMPDIR/jldc.txt"
HT_LIST="$TMPDIR/hackertarget.txt"
OTX_LIST="$TMPDIR/otx.txt"
WAYBACK_LIST="$TMPDIR/wayback.txt"
touch "$CRT_LIST" "$JLDC_LIST" "$HT_LIST" "$OTX_LIST" "$WAYBACK_LIST"

# ---------------------- 1) crt.sh ----------------------
echo -ne "${CYAN}[*] crt.sh sorgulanıyor...${NC} "
CRT_RESPONSE=$(curl -s --max-time 30 -A "Mozilla/5.0" "https://crt.sh/?q=%25.${DOMAIN}&output=json")
if [[ -n "$CRT_RESPONSE" ]]; then
    echo "$CRT_RESPONSE" | jq -r '.[].name_value' 2>/dev/null | sed 's/\\n/\n/g' > "$CRT_LIST"
fi
CNT=$(grep -v '^$' "$CRT_LIST" 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}${CNT} sonuç${NC}"

# ---------------------- 2) jldc.me (crt.sh alternatif ayna) ----------------------
echo -ne "${CYAN}[*] jldc.me sorgulanıyor...${NC} "
JLDC_RESPONSE=$(curl -s --max-time 20 -A "Mozilla/5.0" "https://jldc.me/anubis/subdomains/${DOMAIN}")
if [[ -n "$JLDC_RESPONSE" ]]; then
    echo "$JLDC_RESPONSE" | jq -r '.[]' 2>/dev/null > "$JLDC_LIST"
fi
CNT=$(grep -v '^$' "$JLDC_LIST" 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}${CNT} sonuç${NC}"

# ---------------------- 3) HackerTarget ----------------------
echo -ne "${CYAN}[*] HackerTarget sorgulanıyor...${NC} "
HT_RESPONSE=$(curl -s --max-time 20 -A "Mozilla/5.0" "https://api.hackertarget.com/hostsearch/?q=${DOMAIN}")
if [[ -n "$HT_RESPONSE" && "$HT_RESPONSE" != *"error"* && "$HT_RESPONSE" != *"API count exceeded"* ]]; then
    echo "$HT_RESPONSE" | cut -d',' -f1 > "$HT_LIST"
fi
CNT=$(grep -v '^$' "$HT_LIST" 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}${CNT} sonuç${NC}"

# ---------------------- 4) AlienVault OTX ----------------------
echo -ne "${CYAN}[*] AlienVault OTX sorgulanıyor...${NC} "
OTX_RESPONSE=$(curl -s --max-time 20 -A "Mozilla/5.0" "https://otx.alienvault.com/api/v1/indicators/domain/${DOMAIN}/passive_dns")
if [[ -n "$OTX_RESPONSE" ]]; then
    echo "$OTX_RESPONSE" | jq -r '.passive_dns[].hostname' 2>/dev/null > "$OTX_LIST"
fi
CNT=$(grep -v '^$' "$OTX_LIST" 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}${CNT} sonuç${NC}"

# ---------------------- 5) Wayback Machine (CDX API) ----------------------
echo -ne "${CYAN}[*] Wayback Machine sorgulanıyor...${NC} "
WAYBACK_RESPONSE=$(curl -s --max-time 25 -A "Mozilla/5.0" \
    "http://web.archive.org/cdx/search/cdx?url=*.${DOMAIN}/*&output=text&fl=original&collapse=urlkey&limit=100000")
if [[ -n "$WAYBACK_RESPONSE" ]]; then
    echo "$WAYBACK_RESPONSE" | awk -F/ '{print $3}' > "$WAYBACK_LIST"
fi
CNT=$(grep -v '^$' "$WAYBACK_LIST" 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}${CNT} sonuç${NC}"

echo ""

# ---------------------- Tüm kaynakları birleştir + temizle ----------------------
cat "$CRT_LIST" "$JLDC_LIST" "$HT_LIST" "$OTX_LIST" "$WAYBACK_LIST" \
    | sed 's/\*\.//g' \
    | tr '[:upper:]' '[:lower:]' \
    | tr -d '\r' \
    | sed 's/^\.//' \
    | grep -v '^$' \
    | grep -E "(^|\.)$(printf '%s' "$DOMAIN" | sed 's/\./\\./g')$" \
    | sort -u > "$RAW_LIST"

TOTAL_FOUND=$(wc -l < "$RAW_LIST" | tr -d ' ')

if [[ "$TOTAL_FOUND" -eq 0 ]]; then
    echo -e "${YELLOW}[!] Hiçbir kaynakta bu domain için subdomain bulunamadı.${NC}"
    exit 0
fi

echo -e "${GREEN}${BOLD}[+] Tüm kaynaklardan toplam ${TOTAL_FOUND} benzersiz subdomain bulundu.${NC}"
echo -e "${CYAN}[*] Subdomainlerin canlılık durumu kontrol ediliyor (paralel, ${THREADS} thread)...${NC}"
echo ""

# ---------------------- Canlılık + HTTP durum kodu kontrolü ----------------------
# Her subdomain için hem https hem http denenir, ilk yanıt veren kullanılır.
# Yanıt vermeyenler ("Bağlantı hatası") direkt elenir, ekrana/dosyaya yazılmaz.

check_host() {
    local host="$1"
    local url code scheme

    for scheme in https http; do
        code=$(curl -s -o /dev/null -w "%{http_code}" \
                    --max-time "$TIMEOUT" \
                    -L --insecure \
                    -A "Mozilla/5.0 (SubdomainChecker)" \
                    "${scheme}://${host}" 2>/dev/null)

        # curl boş çıktı verirse (bağlantı kurulamadı) code boş ya da 000 olur
        if [[ -n "$code" && "$code" != "000" ]]; then
            echo "${host}|${scheme}|${code}"
            return 0
        fi
    done
    # Hiçbir protokolde yanıt yoksa hiçbir şey yazdırma -> elenmiş olur
    return 1
}

export -f check_host
export TIMEOUT

# xargs ile paralel kontrol, sonuçları geçici dosyaya yaz
cat "$RAW_LIST" | xargs -P "$THREADS" -I{} bash -c 'check_host "$@"' _ {} > "$ALIVE_LIST"

# Host adına göre sırala
sort -t'|' -k1,1 "$ALIVE_LIST" -o "$ALIVE_LIST"

ALIVE_COUNT=$(wc -l < "$ALIVE_LIST" | tr -d ' ')
DEAD_COUNT=$(( TOTAL_FOUND - ALIVE_COUNT ))

# ---------------------- Ekrana renkli yazdırma ----------------------
{
    echo "# Subdomain Tarama Sonuçları"
    echo "# Domain     : $DOMAIN"
    echo "# Tarih      : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Toplam bulunan (tüm kaynaklar): $TOTAL_FOUND"
    echo "# Ayakta olan            : $ALIVE_COUNT"
    echo "# Yanıt vermeyen (atlandı): $DEAD_COUNT"
    echo "#"
    echo "# FORMAT: subdomain | protokol | http_kodu"
    echo ""
} > "$OUTFILE"

while IFS='|' read -r host scheme code; do
    [[ -z "$host" ]] && continue

    if [[ "$code" =~ ^2 ]]; then
        icon="✅"
        color="$GREEN"
    elif [[ "$code" =~ ^3 ]]; then
        icon="↪️ "
        color="$YELLOW"
    elif [[ "$code" =~ ^4 ]]; then
        icon="⚠️ "
        color="$YELLOW"
    elif [[ "$code" =~ ^5 ]]; then
        icon="❌"
        color="$RED"
    else
        icon="❓"
        color="$RED"
    fi

    printf "${color}%s %-45s [%s] %s${NC}\n" "$icon" "$host" "$scheme" "$code"

    printf "%s | %s | %s\n" "$host" "$scheme" "$code" >> "$OUTFILE"

done < "$ALIVE_LIST"

echo ""
echo -e "${CYAN}${BOLD}---------------------------------------------${NC}"
echo -e "${GREEN}[+] Ayakta olan subdomain sayısı : $ALIVE_COUNT${NC}"
echo -e "${YELLOW}[-] Yanıt vermeyen (atlandı)     : $DEAD_COUNT${NC}"
echo -e "${CYAN}[*] Sonuçlar dosyaya yazıldı      : $OUTFILE${NC}"
echo -e "${CYAN}${BOLD}---------------------------------------------${NC}"
