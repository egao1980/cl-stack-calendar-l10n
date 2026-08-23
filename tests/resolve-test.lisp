(in-package #:cl-stack-calendar-l10n/tests)

(deftest parse-style-valid
  (ok (eq :full (parse-style "full")))
  (ok (eq :short (parse-style "SHORT")))
  (ok (signals (parse-style "tiny") 'cli:cli-usage-error)))

(deftest resolve-locales-defaults-and-countries
  (ok (equal *default-locale-tags* (resolve-locales nil nil)))
  (ok (equal '("ja" "fr") (resolve-locales "ja,fr" nil)))
  (ok (equal '("ja-JP" "he-IL") (resolve-locales nil "JP,IL")))
  (ok (equal '("fr" "ja-JP") (resolve-locales "fr" "JP")))
  (ok (equal '("ja" "fr") (resolve-locales "ja,fr" "JP"))))

(deftest resolve-countries-from-locales
  (ok (equal '("JP" "IL") (resolve-countries nil '("ja" "he"))))
  (ok (equal '("DE" "FR") (resolve-countries "de,fr" '("ja")))))

(deftest parse-date-only-midnight-in-zone
  (let* ((zone (resolve-zone "UTC"))
         (zm (parse-datetime-spec "2024-07-04" zone)))
    (ok (= 2024 (dt:date-year (dt:zoned-moment-date zm))))
    (ok (= 7 (dt:date-month (dt:zoned-moment-date zm))))
    (ok (= 4 (dt:date-day (dt:zoned-moment-date zm))))
    (ok (zerop (dt:time-of-day-hour (dt:zoned-moment-time zm))))))

(deftest parse-rfc3339-converts-to-requested-zone
  (let* ((zone (resolve-zone "UTC"))
         (zm (parse-datetime-spec "2024-07-04T12:00:00-04:00" zone)))
    (ok (= 16 (dt:time-of-day-hour (dt:zoned-moment-time zm))))
    (ok (= 4 (dt:date-day (dt:zoned-moment-date zm))))))

(deftest parse-naive-moment-in-zone
  (let* ((zone (resolve-zone "UTC"))
         (zm (parse-datetime-spec "2024-07-04T15:30:00" zone)))
    (ok (= 15 (dt:time-of-day-hour (dt:zoned-moment-time zm))))
    (ok (= 30 (dt:time-of-day-minute (dt:zoned-moment-time zm))))))

(deftest resolve-location-city
  (ok (string= "Asia/Tokyo" (resolve-location "tokyo")))
  (ok (string= "Europe/London" (resolve-location "London")))
  (ok (signals (resolve-location "atlantis") 'cli:cli-usage-error)))

(deftest resolve-zone-offset
  (let ((z (resolve-zone "+05:30")))
    (ok (typep z 'dt:fixed-offset-zone))
    (ok (= 19800 (dt:zone-offset-seconds z)))))
