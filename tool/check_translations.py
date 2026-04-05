"""Find context.tr keys used in lib/ missing from each locale in app_string.dart."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_STRING = ROOT / "lib/utils/app_string.dart"
LIB = ROOT / "lib"

LOCALE_ORDER = [
    "en",
    "ar",
    "my",
    "fr",
    "de",
    "gu",
    "hi",
    "id",
    "it",
    "ja",
    "ko",
    "ms",
    "mr",
    "fa",
    "pl",
    "pt",
    "es",
    "sv",
    "ta",
    "ur",
]


def parse_locale_keys(text: str) -> dict[str, set[str]]:
    """Extract keys per locale from AppStrings.translations."""
    result: dict[str, set[str]] = {loc: set() for loc in LOCALE_ORDER}
    lines = text.splitlines()
    current: str | None = None
    for line in lines:
        mloc = re.match(r"\s+'([a-z]{2})':\s*\{", line)
        if mloc:
            loc = mloc.group(1)
            if loc in result:
                current = loc
            else:
                current = None
            continue
        if current and re.match(r"\s+\},", line):
            # end of locale map — next line might be next locale
            pass
        if current:
            mk = re.match(r'\s+["\']([^"\']+)["\']\s*:', line)
            if mk:
                result[current].add(mk.group(1))
    return result


def collect_used_keys() -> set[str]:
    used: set[str] = set()
    tr_re = re.compile(
        r"(?:context|blocCtx|currentContext\?)\.tr\(\s*['\"]([^'\"]+)['\"]"
    )
    app_text_re = re.compile(r"AppText\(\s*['\"]([^'\"]+)['\"]")
    for f in LIB.rglob("*.dart"):
        if "_dup" in f.name:
            continue
        try:
            s = f.read_text(encoding="utf-8")
        except OSError:
            continue
        for m in tr_re.finditer(s):
            used.add(m.group(1))
        for m in app_text_re.finditer(s):
            used.add(m.group(1))
    return used


def main() -> None:
    text = APP_STRING.read_text(encoding="utf-8")
    by_locale = parse_locale_keys(text)
    en_keys = by_locale["en"]
    used = collect_used_keys()
    missing_in_en = sorted(used - en_keys)
    print(f"en has {len(en_keys)} keys, used static tr keys: {len(used)}")
    print(f"Missing from en: {len(missing_in_en)}")
    for k in missing_in_en[:100]:
        print(" ", k)
    if len(missing_in_en) > 100:
        print(" ...")

    # Keys in en but missing in other locales
    print("\nPer-locale missing vs en:")
    for loc in LOCALE_ORDER:
        if loc == "en":
            continue
        missing = sorted(en_keys - by_locale[loc])
        if missing:
            print(f"  {loc}: {len(missing)} missing — sample: {missing[:12]}")


if __name__ == "__main__":
    main()
