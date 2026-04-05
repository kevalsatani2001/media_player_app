from pathlib import Path

p = Path(__file__).resolve().parent.parent / "lib/utils/app_string.dart"
lines = p.read_text(encoding="utf-8").splitlines(keepends=True)
out: list[str] = []
for i, line in enumerate(lines):
    out.append(line)
    # Myanmar abCleared line (unique substring)
    if (
        '"abCleared": "A-B ထပ်ခါတလဲလဲကို ပယ်ဖျက်ပြီးပြီ"' in line
        and i > 800
        and i < 1300
    ):
        out.append(
            '      "abSetPointA": "အမှတ် A သတ်မှတ်ရန်",\n'
            '      "abSetPointB": "အမှတ် B သတ်မှတ်ရန်",\n'
            '      "abClearRepeat": "A-B ထပ်ခါတလဲလဲကို ရှင်းရန်",\n'
        )

p.write_text("".join(out), encoding="utf-8")
print("ok")
