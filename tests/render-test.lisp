(in-package #:cl-stack-calendar-l10n/tests)

(deftest print-report-contains-sections
  (let* ((r (build-report :datetime "2024-07-04T12:00:00"
                          :timezone "UTC"
                          :locales "en,fr"
                          :countries "US"
                          :calendars "gregorian,hebrew"))
         (text (with-output-to-string (s)
                 (print-report r s))))
    (ok (search "LOCALES" text))
    (ok (search "CALENDARS" text))
    (ok (search "HOLIDAYS" text))
    (ok (search "French" text))
    (ok (search "Hebrew" text))
    (ok (search "Independence" text))
    (ok (search "2024-07-04" text))))

(deftest cli-list-catalog
  (let ((text (with-output-to-string (*standard-output*)
                (cli:run (make-app) :argv '("--list")))))
    (ok (search "gregorian" text))
    (ok (search "islamic" text))
    (ok (search "tokyo" text))
    (ok (search "DEFAULT LOCALES" text))))

(deftest cli-datetime-and-timezone
  (let ((text (with-output-to-string (*standard-output*)
                (cli:run (make-app)
                         :argv '("--datetime" "2024-07-04T08:00:00"
                                 "--timezone" "Asia/Tokyo"
                                 "--locales" "en,ja"
                                 "--calendars" "gregorian,japanese"
                                 "--countries" "JP,US")))))
    (ok (search "Asia/Tokyo" text))
    (ok (search "Japanese" text))
    (ok (or (search "2024-07-04" text) (search "令和" text)))))
