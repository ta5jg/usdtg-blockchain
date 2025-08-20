import pandas as pd
from ics import Calendar, Event
from datetime import datetime

# CSV dosyasını yükle (bizim hazırladığımız paralel plan CSV'si)
df = pd.read_csv("usdtg_cosmos_blockchain_parallel_plan.csv")

cal = Calendar()

for _, row in df.iterrows():
    e = Event()
    e.name = f"{row['Task']} ({row['Phase']})"
    e.begin = datetime.strptime(row['Due date'], "%Y-%m-%d")
    e.make_all_day()
    e.description = f"Assignee: {row['Assignee']}\nPriority: {row['Priority']}\nStatus: {row['Status']}"
    cal.events.add(e)

# ICS dosyasını kaydet
with open("usdtg_cosmos_blockchain_parallel_plan.ics", "w", encoding="utf-8") as f:
    f.writelines(cal)

print("✅ ICS dosyası oluşturuldu: usdtg_cosmos_blockchain_parallel_plan.ics")