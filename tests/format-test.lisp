(in-package #:cl-stack-calendar-l10n/tests)

(defun %fixed-report (&rest args)
  (let* ((zone (resolve-zone "UTC"))
         (instant (dt:zoned-moment-to-instant
                   (parse-datetime-spec "2024-07-04T12:00:00" zone))))
    (dt:with-fixed-clock (instant)
      (apply #'build-report :datetime "2024-07-04T12:00:00" :timezone "UTC" args))))

(deftest build-report-locale-and-calendar-rows
  (let ((r (%fixed-report :locales "ja,fr,en" :calendars "gregorian,japanese,hebrew"
                          :holidays nil)))
    (ok (= 3 (length (report-locale-rows r))))
    (ok (= 3 (length (report-calendar-rows r))))
    (ok (null (report-holiday-countries r)))
    (let ((ja (find "ja" (report-locale-rows r) :key #'locale-row-tag :test #'string=))
          (en (find "en" (report-locale-rows r) :key #'locale-row-tag :test #'string=)))
      (ok (plusp (length (locale-row-native ja))))
      (ok (plusp (length (locale-row-english ja))))
      (ok (null (locale-row-english en)))
      (ok (search "2024" (locale-row-native en)))
      (ok (or (search "12:00" (locale-row-native en))
              (search "12:00" (locale-row-native ja)))))))

(deftest japanese-and-french-look-localized
  (let* ((r (%fixed-report :locales "ja,fr" :calendars "japanese" :holidays nil))
         (ja (find "ja" (report-locale-rows r) :key #'locale-row-tag :test #'string=))
         (fr (find "fr" (report-locale-rows r) :key #'locale-row-tag :test #'string=))
         (jp-cal (first (report-calendar-rows r))))
    (ok (or (find #\年 (locale-row-native ja))
            (search "2024" (locale-row-native ja))))
    (ok (or (search "juillet" (string-downcase (locale-row-native fr)))
            (search "2024" (locale-row-native fr))))
    (ok (or (find #\令 (calendar-row-native jp-cal))
            (search "Reiwa" (calendar-row-english jp-cal))
            (search "2024" (calendar-row-native jp-cal))))))

(deftest no-english-flag
  (let ((r (%fixed-report :locales "fr" :english nil :holidays nil :calendars "gregorian")))
    (ok (null (locale-row-english (first (report-locale-rows r)))))
    (ok (null (calendar-row-english (first (report-calendar-rows r)))))))
