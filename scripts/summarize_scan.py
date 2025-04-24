import json
import sys
from collections import Counter
from pathlib import Path

input_file = Path(sys.argv[1])

type_counts = Counter()
with input_file.open() as f:
    for line in f:
        try:
            obj = json.loads(line)
            type_counts[obj.get("type", "UNKNOWN")] += 1
        except json.JSONDecodeError:
            continue

print(f"\nSummary for {input_file.name}:")
for t, c in type_counts.most_common():
    print(f"  {t:<20} {c}")