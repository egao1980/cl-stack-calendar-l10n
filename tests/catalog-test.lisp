(in-package #:cl-stack-calendar-l10n/tests)

(deftest split-csv-basic
  (ok (equal '("ja" "fr" "de") (split-csv "ja,fr,de")))
  (ok (equal '("ja" "fr") (split-csv " ja , fr ")))
  (ok (null (split-csv "")))
  (ok (null (split-csv nil))))

(deftest flatten-names-list-and-commas
  (ok (equal '("ja" "fr" "he") (flatten-names '("ja,fr" "he"))))
  (ok (equal '("US" "JP") (flatten-names "US, JP"))))

(deftest calendar-aliases
  (ok (string= "islamic" (calendar-spec-id (find-calendar-spec "hijri"))))
  (ok (string= "hebrew" (calendar-spec-id (find-calendar-spec "Jewish"))))
  (ok (string= "persian" (calendar-spec-id (find-calendar-spec "jalali"))))
  (ok (string= "buddhist" (calendar-spec-id (find-calendar-spec "thai"))))
  (ok (signals (find-calendar-spec "aztec") 'cli:cli-usage-error)))

(deftest default-calendars-are-major
  (let ((ids (mapcar #'calendar-spec-id (default-calendar-specs))))
    (ok (equal '("gregorian" "islamic" "hebrew" "chinese" "japanese"
                 "indian" "buddhist" "persian" "ethiopic")
               ids))))

(deftest english-locale-detect
  (ok (english-locale-p "en"))
  (ok (english-locale-p "en-GB"))
  (ok (english-locale-p "en_US"))
  (ng (english-locale-p "fr"))
  (ng (english-locale-p "enx")))

(deftest locale-region-and-calendar-tag
  (ok (string-equal "US" (locale-region "en-US")))
  (ok (string-equal "CN" (locale-region "zh-Hans-CN")))
  (ok (null (locale-region "zh-Hans")))
  (ok (string= "ja@calendar=japanese" (locale-with-calendar "ja" "japanese"))))

(deftest country-and-location-tables
  (ok (string= "ja-JP" (country-locale "JP")))
  (ok (string= "Asia/Tokyo" (location-zone "tokyo")))
  (ok (string= "America/New_York" (location-zone "New York")))
  (ok (string= "Asia/Riyadh" (location-zone "mecca"))))
