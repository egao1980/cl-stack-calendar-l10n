(in-package #:cl-stack-calendar-l10n)

(defun %zoneinfo-suffix (path)
  (let* ((s (namestring path))
         (key "/zoneinfo/")
         (pos (search key s)))
    (when pos
      (let ((id (subseq s (+ pos (length key)))))
        (when (plusp (length id))
          id)))))

(defun local-zone-id ()
  "Best-effort IANA id: $TZ, then /etc/localtime symlink, else UTC."
  (or (let ((tz (uiop:getenv "TZ")))
        (when (and tz (plusp (length tz)))
          (let ((trimmed (string-left-trim '(#\:) tz)))
            (cond
              ((zerop (length trimmed)) nil)
              ((search "localtime" trimmed) nil)
              (t trimmed)))))
      (ignore-errors
        (let* ((p #p"/etc/localtime")
               (true (and (probe-file p) (truename p))))
          (when true
            (%zoneinfo-suffix true))))
      "UTC"))

(defun resolve-zone (zone-name)
  "ZONE-NAME is an IANA id, offset like +01:00, or NIL (local)."
  (let ((id (or (and zone-name (plusp (length (string-trim '(#\Space) zone-name)))
                     (string-trim '(#\Space) zone-name))
                (local-zone-id))))
    (cond
      ((member id '("UTC" "Etc/UTC" "Z" "zulu" "Zulu") :test #'string-equal)
       dt:+utc+)
      ((and (plusp (length id))
            (member (char id 0) '(#\+ #\-)))
       (dt:make-fixed-offset-zone
        (let* ((sign (if (char= (char id 0) #\-) -1 1))
               (rest (subseq id 1))
               (colon (position #\: rest))
               (hh (parse-integer rest :end (or colon (min 2 (length rest)))))
               (mm (if colon (parse-integer rest :start (1+ colon)) 0)))
          (* sign (+ (* hh 3600) (* mm 60))))))
      (t (dt:resolve-zone-id id)))))

(defun resolve-location (name)
  "Return IANA zone id for a place name, lat,lon pair, or IANA id. NIL if NAME is empty."
  (let ((s (and name (string-trim '(#\Space #\Tab) name))))
    (when (and s (plusp (length s)))
      (or (location-zone s)
          (let ((comma (position #\, s)))
            (when comma
              ;; lat,lon — civil zone still required; treat as a label only
              (error 'cli:cli-usage-error
                     :message "lat,lon needs --timezone (location is not a zone)")))
          (handler-case
              (progn (dt:resolve-zone-id s) s)
            (dt:zone-not-found ()
              (error 'cli:cli-usage-error
                     :message (format nil "unknown location ~s (city name or IANA zone)"
                                      s))))))))

(defun parse-style (value)
  (let ((s (string-downcase (or value "full"))))
    (cond
      ((member s '("full" "long" "medium" "short") :test #'string=)
       (intern (string-upcase s) :keyword))
      (t (error 'cli:cli-usage-error
                :message "style must be full, long, medium, or short")))))

(defun parse-datetime-spec (string zone)
  "STRING empty → now in ZONE.
   YYYY-MM-DD → midnight in ZONE.
   RFC 3339 with offset → that instant observed in ZONE.
   Naive YYYY-MM-DDTHH:MM:SS → wall time in ZONE."
  (let ((s (and string (string-trim '(#\Space #\Tab) string))))
    (cond
      ((or (null s) (zerop (length s)))
       (dt:instant-in-zone (dt:now) zone))
      ((and (= (length s) 10)
            (char= (char s 4) #\-)
            (char= (char s 7) #\-))
       (dt:moment-in-zone (dt:make-moment (dt:parse-iso-date s) dt:+midnight+) zone))
      (t
       (let ((normalized (substitute #\T #\Space s)))
         (handler-case
             (let ((zm (dt:parse-rfc3339 normalized)))
               (dt:instant-in-zone (dt:zoned-moment-to-instant zm) zone))
           (dt:datetime-parse-error ()
             (dt:moment-in-zone (dt:parse-moment normalized) zone))))))))

(defun resolve-calendars (names)
  (let ((ids (flatten-names names)))
    (if ids
        (mapcar #'find-calendar-spec ids)
        (default-calendar-specs))))

(defun %unique-strings (items)
  (let ((seen (make-hash-table :test #'equal))
        (out '()))
    (dolist (item items)
      (when (and item (plusp (length item)))
        (let ((key (string item)))
          (unless (gethash key seen)
            (setf (gethash key seen) t)
            (push key out)))))
    (nreverse out)))

(defun resolve-locales (locale-names country-codes)
  "Locales from --locales, plus primary locales of --countries. Default table if both empty."
  (let* ((from-locales (flatten-names locale-names))
         (from-countries
           (loop for code in (flatten-names country-codes)
                 for loc = (country-locale code)
                 collect (or loc
                             (error 'cli:cli-usage-error
                                    :message (format nil "no default locale for country ~s" code))))))
    (or (%unique-strings (append from-locales from-countries))
        (copy-list *default-locale-tags*))))

(defun country-for-locale (tag)
  (or (%assoc-ci tag *locale-countries*)
      (%assoc-ci (locale-language tag) *locale-countries*)
      (let ((region (locale-region tag)))
        (when region (string-upcase region)))))

(defun resolve-countries (country-codes locale-tags)
  "Holiday country set: explicit --countries, else regions inferred from locales."
  (let ((explicit (mapcar #'string-upcase (flatten-names country-codes))))
    (if explicit
        (%unique-strings explicit)
        (%unique-strings
         (mapcar #'country-for-locale locale-tags)))))
