(in-package #:cl-stack-calendar-l10n)

(defparameter +label-width+ 26)

(defun %pad-label (label)
  (let* ((s (string label))
         (n (length s)))
    (if (>= n +label-width+)
        (concatenate 'string (subseq s 0 (- +label-width+ 1)) "…")
        (concatenate 'string s (make-string (- +label-width+ n) :initial-element #\Space)))))

(defun %rule (stream &optional (char #\─) (n 60))
  (format stream "~&  ~A~%" (make-string n :initial-element char)))

(defun %section (stream title)
  (format stream "~&~%~A~%" title)
  (%rule stream #\─ (max 8 (length title))))

(defun %row (stream label primary &optional english)
  (format stream "  ~A~A~%" (%pad-label label) primary)
  (when (and english (not (string= english primary)))
    (format stream "  ~A~A~%" (%pad-label "") english)))

(defun %offset-label (zoned)
  (let ((off (dt:zoned-moment-offset-seconds zoned)))
    (if (zerop off)
        "UTC"
        (multiple-value-bind (h m) (floor (floor (abs off) 60) 60)
          (format nil "~:[+~;-~]~2,'0d:~2,'0d" (minusp off) h m)))))

(defun %weekday-en (date)
  (aref #("Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
        (1- (dt:date-day-of-week date))))

(defun print-report (report &optional (stream *standard-output*))
  (let* ((zoned (report-zoned report))
         (date (report-date report))
         (tod (dt:zoned-moment-time zoned))
         (abbr (ignore-errors
                 (dt:zone-abbreviation-for-instant (report-zone report)
                                                   (report-instant report))))
         (iso (dt:print-iso-date date))
         (time (format nil "~2,'0d:~2,'0d:~2,'0d"
                       (dt:time-of-day-hour tod)
                       (dt:time-of-day-minute tod)
                       (dt:time-of-day-second tod))))
    (format stream "~%")
    (%rule stream #\━ 64)
    (format stream "  ~A ~4,'0d-~2,'0d-~2,'0d  ·  ~A~%"
            (%weekday-en date) (dt:date-year date) (dt:date-month date) (dt:date-day date)
            time)
    (format stream "  ~A~@[  ·  ~A~]  ·  ~A~%"
            (report-zone-id report)
            (and abbr (not (string-equal abbr (report-zone-id report))) abbr)
            (%offset-label zoned))
    (format stream "  ~A~%" (report-rfc3339 report))
    (%rule stream #\━ 64)

    (%section stream "LOCALES")
    (dolist (row (report-locale-rows report))
      (%row stream
            (format nil "~A (~A)" (locale-row-label row) (locale-row-tag row))
            (locale-row-native row)
            (locale-row-english row)))

    (%section stream "CALENDARS")
    (dolist (row (report-calendar-rows report))
      (let ((spec (calendar-row-spec row)))
        (%row stream
              (calendar-spec-label spec)
              (calendar-row-native row)
              (calendar-row-english row))))

    (when (report-holiday-countries report)
      (%section stream (format nil "HOLIDAYS  ~A" iso))
      (let ((hits (report-holiday-rows report))
            (codes (report-holiday-countries report)))
        (if hits
            (dolist (row hits)
              (%row stream
                    (format nil "~A  ~A" (holiday-row-code row) (holiday-row-country row))
                    (holiday-row-name row)))
            (format stream "  none~%"))
        (format stream "~&  checked ~D countr~:@P · ~D holiday~:P~%"
                (length codes) (length hits))))
    (terpri stream)
    report))

(defun print-catalog (&optional (stream *standard-output*))
  (%section stream "CALENDARS")
  (dolist (spec *calendar-specs*)
    (format stream "  ~A  ~A~@[  (aliases: ~{~A~^, ~})~]~:[~;  *default*~]~%"
            (%pad-label (calendar-spec-id spec))
            (calendar-spec-label spec)
            (calendar-spec-aliases spec)
            (calendar-spec-default spec)))
  (%section stream "DEFAULT LOCALES")
  (dolist (tag *default-locale-tags*)
    (format stream "  ~A  ~A~%" (%pad-label tag) (locale-label tag)))
  (%section stream "COUNTRIES")
  (dolist (pair (sort (copy-list *country-locales*) #'string< :key #'car))
    (format stream "  ~A  ~A  →  ~A~%"
            (car pair)
            (%pad-label (country-label (car pair)))
            (cdr pair)))
  (%section stream "LOCATIONS")
  (dolist (pair (list-locations))
    (format stream "  ~A  ~A~%" (%pad-label (car pair)) (cdr pair)))
  (terpri stream)
  t)

(defun report-and-print (&rest args &key (stream *standard-output*) &allow-other-keys)
  (let ((opts (copy-list args)))
    (remf opts :stream)
    (print-report (apply #'build-report opts) stream)))
