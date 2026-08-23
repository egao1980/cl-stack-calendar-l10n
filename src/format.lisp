(in-package #:cl-stack-calendar-l10n)

(defstruct report
  instant
  zone
  zone-id
  zoned
  date
  rfc3339
  locale-rows
  calendar-rows
  holiday-rows
  holiday-countries)

(defstruct locale-row
  tag
  label
  native
  english)

(defstruct calendar-row
  spec
  native
  english)

(defun wall-unix-seconds (zoned)
  "Civil wall time of ZONED as Unix seconds, pretending the clock is UTC.
   ICU formatters use the process default zone; this keeps Y-M-D h:m:s stable."
  (dt:instant-seconds
   (dt:zoned-moment-to-instant
    (dt:make-zoned-moment (dt:zoned-moment-moment zoned) 0 dt:+utc+))))

(defun date-skeleton (style)
  (ecase style
    (:full "yMMMMdEEEE")
    (:long "yMMMMd")
    (:medium "yMMMd")
    (:short "yMd")))

(defun datetime-skeleton (style)
  (ecase style
    (:full "yMMMMdEEEE Hms")
    (:long "yMMMMd Hms")
    (:medium "yMMMd Hm")
    (:short "yMd Hm")))

(defun format-locale-date (unix locale &key (style :full) (time t) calendar)
  (let ((tag (if calendar
                 (locale-with-calendar locale calendar)
                 locale)))
    (if time
        (l10n:format-datetime unix :locale tag :skeleton (datetime-skeleton style))
        (l10n:format-date unix :locale tag :skeleton (date-skeleton style)))))

(defun %english-parallel (unix locale &key (style :full) (time t) calendar)
  (unless (english-locale-p locale)
    (format-locale-date unix "en" :style style :time time :calendar calendar)))

(defun zone-id-string (zone)
  (cond
    ((eq zone dt:+utc+) "UTC")
    ((typep zone 'dt:named-zone) (dt:zone-name zone))
    ((typep zone 'dt:fixed-offset-zone)
     (let ((off (dt:zone-offset-seconds zone)))
       (if (zerop off)
           "UTC"
           (multiple-value-bind (h m) (floor (floor (abs off) 60) 60)
             (format nil "~:[+~;-~]~2,'0d:~2,'0d" (minusp off) h m)))))
    (t (princ-to-string zone))))

(defun build-report (&key datetime timezone location locales countries calendars
                       (style :full) (english t) (holidays t))
  (let* (         (zone-id (or (and timezone (plusp (length (string-trim '(#\Space) timezone)))
                           (string-trim '(#\Space) timezone))
                      (and location (resolve-location location))
                      (local-zone-id)))
         (zone (resolve-zone zone-id))
         (zoned (parse-datetime-spec datetime zone))
         (instant (dt:zoned-moment-to-instant zoned))
         (date (dt:zoned-moment-date zoned))
         (unix (wall-unix-seconds zoned))
         (locale-tags (resolve-locales locales countries))
         (cal-specs (resolve-calendars calendars))
         (holiday-codes (and holidays (resolve-countries countries locale-tags)))
         (locale-rows
           (mapcar (lambda (tag)
                     (make-locale-row
                      :tag tag
                      :label (locale-label tag)
                      :native (format-locale-date unix tag :style style :time t)
                      :english (and english
                                    (%english-parallel unix tag :style style :time t))))
                   locale-tags))
         (calendar-rows
           (mapcar (lambda (spec)
                     (make-calendar-row
                      :spec spec
                      :native (format-locale-date unix (calendar-spec-native-locale spec)
                                                  :style style :time nil
                                                  :calendar (calendar-spec-icu-id spec))
                      :english (and english
                                    (format-locale-date unix "en"
                                                        :style style :time nil
                                                        :calendar (calendar-spec-icu-id spec)))))
                   cal-specs)))
    (make-report
     :instant instant
     :zone zone
     :zone-id (zone-id-string zone)
     :zoned zoned
     :date date
     :rfc3339 (dt:print-rfc3339 zoned)
     :locale-rows locale-rows
     :calendar-rows calendar-rows
     :holiday-rows (if holidays (holidays-on date holiday-codes) nil)
     :holiday-countries holiday-codes)))
