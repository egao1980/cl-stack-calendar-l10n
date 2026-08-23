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

```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Thursday 2024-07-04  ·  08:00:00
  Asia/Tokyo  ·  +09:00
  2024-07-04T08:00:00+09:00
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LOCALES
  English (en)              Thursday, July 4, 2024 at 08:00:00
  Japanese (ja)             2024年7月4日木曜日 8:00:00
                            Thursday, July 4, 2024 at 08:00:00
  French (fr)               jeudi 4 juillet 2024 à 08:00:00
                            Thursday, July 4, 2024 at 08:00:00
  Arabic (ar)               الخميس، 4 يوليو 2024 في 08:00:00
                            Thursday, July 4, 2024 at 08:00:00
  Hebrew (he)               יום חמישי, 4 ביולי 2024 בשעה 8:00:00
                            Thursday, July 4, 2024 at 08:00:00

CALENDARS
  Gregorian                 Thursday, July 4, 2024
  Japanese (nengō)          令和6年7月4日木曜日
                            Thursday, July 4, 6 Reiwa
  Hebrew                    יום חמישי, 28 בסיוון 5784
                            Thursday, 28 Sivan 5784
  Islamic (Hijri)           الخميس، 28 ذو الحجة 1445 هـ
                            Thursday, Dhuʻl-Hijjah 28, 1445 AH

HOLIDAYS  2024-07-04
  US  United States         Independence Day
  checked 3 countries · 1 holiday
```

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

## Binary (SBCL image)

CI dumps a self-contained SBCL executable (`save-lisp-and-die`) plus ICU natives and tz/holiday data for **linux-amd64**, **darwin-arm64**, and **windows-amd64**. Artifacts attach to every run; GitHub Releases publish on `v*` tags and `workflow_dispatch`.

```bash
# local dump (SBCL)
DUMP_DIR=dist/calendar-l10n ros -l scripts/dump-image.lisp -q
./dist/calendar-l10n/calendar-l10n --datetime 2024-07-04 --timezone UTC --countries US
```

The tarball is a directory: `calendar-l10n` (or `.exe`), `lib/` (ICU), `data/tzdata/`, `data/countries/`. Keep that layout — the image retargets search paths from the executable directory on startup. On Windows the ICU DLLs are also copied next to the `.exe`.

## License

MIT
