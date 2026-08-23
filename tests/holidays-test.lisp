(in-package #:cl-stack-calendar-l10n/tests)

(deftest us-independence-day
  (let* ((date (dt:make-date 2024 7 4))
         (rows (holidays-on date '("US"))))
    (ok (= 1 (length rows)))
    (ok (string= "US" (holiday-row-code (first rows))))
    (ok (search "Independence" (holiday-row-name (first rows))))))

(deftest germany-unity-day
  (let ((rows (holidays-on (dt:make-date 2024 10 3) '("DE"))))
    (ok (plusp (length rows)))
    (ok (string= "DE" (holiday-row-code (first rows))))))

(deftest ordinary-weekday-no-us-holiday
  (ok (null (holidays-on (dt:make-date 2024 7 2) '("US")))))

(deftest report-includes-holiday-hits
  (let ((r (build-report :datetime "2024-07-04"
                         :timezone "America/New_York"
                         :locales "en"
                         :countries "US"
                         :calendars "gregorian")))
    (ok (plusp (length (report-holiday-rows r))))
    (ok (string= "US" (holiday-row-code (first (report-holiday-rows r)))))))
