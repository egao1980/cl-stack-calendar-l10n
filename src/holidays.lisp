(in-package #:cl-stack-calendar-l10n)

(defstruct holiday-row
  code
  country
  name)

(defun %country-display-name (code calendar)
  (or (ignore-errors (cal:calendar-name calendar))
      (country-label code)
      code))

(defun holidays-on (date country-codes)
  "HOLIDAY-ROW list for DATE in COUNTRY-CODES (ISO alpha-2). Missing corpora are skipped."
  (loop for code in country-codes
        for cal = (handler-case (cal:country-calendar code)
                    (cal:calendar-not-found () nil))
        when cal
          append (multiple-value-bind (hit name) (cal:holiday-p cal date)
                   (when hit
                     (list (make-holiday-row
                            :code (string-upcase code)
                            :country (%country-display-name (string-upcase code) cal)
                            :name (or name "holiday")))))))
