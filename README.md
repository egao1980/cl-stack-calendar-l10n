# cl-stack-calendar-l10n

Sample [cl-stack](https://github.com/egao1980/cl-stack) app: take a civil datetime (default **local now**) and print it

- localized in a list of **languages** (BCP 47) / **countries** (ISO 3166-1)
- converted across major **calendar systems** (ICU + `datetime-protocol/calendars`)
- with a parallel **English** line for every non-English rendering
- plus **public holidays** on that civil date (`cl-stack-calendars` country corpus)

## Run

```bash
ros -l scripts/run.lisp
ros -l scripts/run.lisp -- --datetime 2026-08-23 --timezone Asia/Tokyo
ros -l scripts/run.lisp -- --datetime 2024-07-04T08:00:00 --location new-york \
    --locales ja,fr,ar,he --calendars gregorian,hebrew,islamic,japanese --countries US,JP,IL
ros -l scripts/run.lisp -- --list
```

| Flag | Meaning |
|------|---------|
| `-d, --datetime` | `YYYY-MM-DD` or RFC 3339. Default: now |
| `-z, --timezone` | IANA id or `±HH:MM`. Default: `$TZ` / `/etc/localtime` |
| `-L, --location` | City (`tokyo`, `mecca`, `london`, …) or IANA id |
| `-l, --locales` | Comma-separated BCP 47 tags |
| `-c, --countries` | ISO country codes → locales + holiday calendars |
| `-C, --calendars` | `gregorian`, `islamic`/`hijri`, `hebrew`, `chinese`, `japanese`, `indian`/`saka`, `buddhist`/`thai`, `persian`/`jalali`, `ethiopic`, … |
| `-s, --style` | `full` (default), `long`, `medium`, `short` |
| `--no-english` | Skip English parallels |
| `--no-holidays` | Skip holiday lookup |
| `--list` | Dump known calendars / locales / countries / locations |

Defaults: 12 major languages; 9 actively used calendar systems (Gregorian, Hijri, Hebrew, Chinese, Japanese nengō, Indian National, Thai Buddhist, Solar Hijri, Ethiopic). Holidays inferred from locale regions, or from `--countries`.

`--timezone` wins over `--location` when both are set.

## Stack

| Piece | Role |
|-------|------|
| `datetime-protocol` + `/calendars` | instant, zone, parse, Hebrew/Islamic/Chinese |
| `cl-stack-tzdata` | IANA zones |
| `l10n-protocol` + `l10n-backend-icu` | locale date format (`@calendar=`) |
| `cl-stack-calendars` | `country-calendar` / `holiday-p` |
| `cli-protocol` + `cli-backend-clingon` | CLI |

## Lisp

```lisp
(asdf:load-system "cl-stack-calendar-l10n")
(calendar-l10n:report-and-print
 :datetime "2024-07-04" :timezone "America/New_York"
 :locales "en,ja" :countries "US" :calendars "gregorian,japanese")
```

## License

MIT
