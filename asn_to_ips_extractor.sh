#!/bin/bash

# التحقق من وجود prips، وإذا مش موجود تثبته
if ! command -v prips &> /dev/null; then
    echo "[!] أداة prips غير موجودة. جاري التثبيت..."
    sudo apt update && sudo apt install -y prips
    if ! command -v prips &> /dev/null; then
        echo "[✗] فشل التثبيت. يرجى تثبيت prips يدوياً."
        exit 1
    else
        echo "[✓] تم تثبيت prips بنجاح."
    fi
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 inputfile"
    exit 1
fi

input_file="$1"
cidr_file="cidrs.txt"
ip_file="ips.txt"

echo "[*] استخراج كل الـ ASNs من الملف $input_file ..."
ASNS=$(grep -oE 'AS[0-9]+' "$input_file" | sort -u)

echo "[*] عدد ASNs المستخرجة: $(echo "$ASNS" | wc -l)"

> "$cidr_file"
> "$ip_file"

echo "[*] جلب رنجات CIDR لكل ASN ..."
for asn in $ASNS; do
    echo "  - جلب رنجات $asn"
    whois -h whois.radb.net -- "-i origin $asn" | grep ^route: | awk '{print $2}' >> "$cidr_file"
done

echo "[*] ترتيب وتنظيف رنجات CIDR ..."
sort -u "$cidr_file" -o "$cidr_file"

echo "[*] تفكيك الرنجات إلى عناوين IP فردية ..."
while read -r cidr; do
    prips "$cidr"
done < "$cidr_file" >> "$ip_file"

echo "[*] عدد عناوين IP التي تم جمعها: $(wc -l < "$ip_file")"

echo "[✓] انتهى. ملف $ip_file جاهز للفحص."
