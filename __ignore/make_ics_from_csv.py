#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re, csv
from datetime import datetime
from pathlib import Path

# ---- Yardımcılar ----
def norm(s: str) -> str:
    # sütun isimlerini normalize: lower + harf/rakam dışını at
    return re.sub(r'[^a-z0-9]', '', s.strip().lower())

# Bu anahtarlar birden fazla olası ismi kapsar
CANDIDATES = {
    "task": {"task","title","name","subject","gorev"},
    "phase": {"phase","sprint","bolum","kategori","group"},
    "status": {"status","durum","state"},
    "assignee": {"assignee","owner","sorumlu","kim"},
    "due_date": {"duedate","date","deadline","tarih","startdate","enddate"},
    "priority": {"priority","oncelik","importance","prio"}
}

def map_columns(header):
    mapping = {}
    normalized = [norm(h) for h in header]
    for key, variants in CANDIDATES.items():
        idx = None
        for i, col in enumerate(normalized):
            if col in variants:
                idx = i
                break
        mapping[key] = idx
    return mapping

def parse_date(s):
    s = s.strip()
    # Yaygın biçimler: YYYY-MM-DD, DD.MM.YYYY, MM/DD/YYYY
    for fmt in ("%Y-%m-%d", "%d.%m.%Y", "%m/%d/%Y", "%d/%m/%Y"):
        try:
            return datetime.strptime(s, fmt).date()
        except Exception:
            pass
    # Son çare: yıl-ayı/günü ayırmayı deneyelim
    try:
        # 2025-9-5 gibi tek haneli formatlar
        parts = re.split(r'[/\.\-]', s)
        parts = [p for p in parts if p]
        if len(parts) == 3:
            y,m,d = sorted(parts, key=len, reverse=True)  # genelde yıl en uzundur
            y = int(y); m = int(m); d = int(d)
            return datetime(y, m, d).date()
    except Exception:
        pass
    raise ValueError(f"Tarih anlaşılamadı: {s!r}")

def ics_escape(text):
    # ICS satır kaçışları
    return text.replace('\\','\\\\').replace(';','\\;').replace(',','\\,').replace('\n','\\n')

def fold_ics_line(line, limit=75):
    # ICS satır uzunluğu katlama (RFC 5545)
    out = []
    while len(line) > limit:
        out.append(line[:limit])
        line = ' ' + line[limit:]
    out.append(line)
    return '\r\n'.join(out)

def make_uid(i):
    return f"{i}-{int(datetime.utcnow().timestamp())}@usdtg"

# ---- Ana İş ----
def main():
    if len(sys.argv) < 3:
        print("Kullanım: python make_ics_from_csv.py <girdi.csv> <cikti.ics>")
        sys.exit(1)

    in_csv = Path(sys.argv[1])
    out_ics = Path(sys.argv[2])

    if not in_csv.exists():
        print(f"Hata: CSV bulunamadı: {in_csv}")
        sys.exit(1)

    # CSV'yi oku (virgül veya noktalı virgül vb. ayraçları destekleyelim)
    with open(in_csv, 'r', encoding='utf-8-sig', newline='') as f:
        sample = f.read(4096)
        f.seek(0)
        try:
            dialect = csv.Sniffer().sniff(sample)
        except Exception:
            dialect = csv.excel
        reader = csv.reader(f, dialect)
        rows = list(reader)

    if not rows:
        print("Hata: CSV boş görünüyor.")
        sys.exit(1)

    header = rows[0]
    data_rows = rows[1:]

    mapping = map_columns(header)

    # En azından Task/Subject ve Due Date/Date alanları bulunmalı
    if mapping["task"] is None and mapping["phase"] is None and mapping["status"] is None and mapping["assignee"] is None and mapping["due_date"] is None:
        print("Hata: Sütunlar eşleştirilemedi. CSV başlıkları:", header)
        print("En azından 'Task/Subject' ve 'Due Date/Start Date/Date' benzeri bir alan olmalı.")
        sys.exit(1)

    # ICS başlıkları
    lines = []
    lines.append("BEGIN:VCALENDAR")
    lines.append("VERSION:2.0")
    lines.append("PRODID:-//USdTG//Calendar//EN")
    lines.append("CALSCALE:GREGORIAN")
    lines.append("METHOD:PUBLISH")

    nowstamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")

    for i, row in enumerate(data_rows, start=1):
        # Güvenlik: Satır uzunluğu kısa ise dolduralım
        while len(row) < len(header):
            row.append("")

        def get(idx):
            return row[idx].strip() if idx is not None and idx < len(row) else ""

        task = get(mapping["task"]) if mapping["task"] is not None else ""
        phase = get(mapping["phase"]) if mapping["phase"] is not None else ""
        status = get(mapping["status"]) if mapping["status"] is not None else ""
        assignee = get(mapping["assignee"]) if mapping["assignee"] is not None else ""
        priority = get(mapping["priority"]) if mapping["priority"] is not None else ""
        due_raw = get(mapping["due_date"]) if mapping["due_date"] is not None else ""

        # Eğer Task boş ve Subject formatında kolon varsa onu yakalayalım
        if not task:
            # Subject/Name/Title biri task yerine geçtiyse mapping zaten yakalayacaktır
            pass

        # Tarih şart
        if not due_raw:
            # Google Calendar CSV'si ise Start Date vardır
            # mapping bunu due_date olarak yakalamaya çalışıyor ama yine de fallback yapalım
            # Başlıklar içinde "Start Date" adını bulalım:
            found = ""
            for j, h in enumerate(header):
                if norm(h) in {"startdate"}:
                    found = row[j].strip()
                    break
            if found:
                due_raw = found

        if not due_raw:
            # Tarih yoksa etkinlik oluşturma, atla
            continue

        try:
            due = parse_date(due_raw)
        except Exception as e:
            # Bu satırı atla ama uyarı vermek isterseniz print edebilirsiniz
            # print(f"Uyarı: Tarih çözümlenemedi (satır {i}): {due_raw!r}")
            continue

        # Başlık oluştur
        title = task or "(Untitled Task)"
        if phase:
            title = f"{title} ({phase})"

        desc_parts = []
        if assignee: desc_parts.append(f"Assignee: {assignee}")
        if priority: desc_parts.append(f"Priority: {priority}")
        if status:   desc_parts.append(f"Status: {status}")
        desc = "\\n".join(desc_parts) if desc_parts else ""

        # All-day event (DTSTART;VALUE=DATE)
        lines.append("BEGIN:VEVENT")
        lines.append(f"UID:{make_uid(i)}")
        lines.append(f"DTSTAMP:{nowstamp}")
        lines.append(fold_ics_line(f"SUMMARY:{ics_escape(title)}"))
        lines.append(f"DTSTART;VALUE=DATE:{due.strftime('%Y%m%d')}")
        # All-day için DTEND, sonraki gün olarak verilir (exclusive)
        dtend = due + __import__('datetime').timedelta(days=1)
        lines.append(f"DTEND;VALUE=DATE:{dtend.strftime('%Y%m%d')}")
        if desc:
            lines.append(fold_ics_line(f"DESCRIPTION:{ics_escape(desc)}"))
        lines.append("END:VEVENT")

    lines.append("END:VCALENDAR")

    out_ics.write_text("\r\n".join(lines), encoding="utf-8")
    print(f"✅ ICS dosyası oluşturuldu: {out_ics}")

if __name__ == "__main__":
    main()