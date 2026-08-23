(in-package #:cl-stack-calendar-l10n)

;;;; Actively used civil / religious calendar systems (ICU @calendar= ids)
;;;; plus language/country/location tables for the CLI.

(defstruct (calendar-spec (:constructor make-calendar-spec))
  (id nil :type string)
  (icu-id nil :type string)
  (label nil :type string)
  (native-locale "en" :type string)
  (aliases nil :type list)
  (default nil :type boolean))

(defparameter *calendar-specs*
  (list
   (make-calendar-spec :id "gregorian" :icu-id "gregorian" :label "Gregorian"
                       :native-locale "en" :aliases '("iso" "iso8601" "western") :default t)
   (make-calendar-spec :id "islamic" :icu-id "islamic" :label "Islamic (Hijri)"
                       :native-locale "ar" :aliases '("hijri" "ummalqura" "hijri-civil") :default t)
   (make-calendar-spec :id "hebrew" :icu-id "hebrew" :label "Hebrew"
                       :native-locale "he" :aliases '("jewish" "luach") :default t)
   (make-calendar-spec :id "chinese" :icu-id "chinese" :label "Chinese lunisolar"
                       :native-locale "zh-Hans" :aliases '("lunar") :default t)
   (make-calendar-spec :id "japanese" :icu-id "japanese" :label "Japanese (nengō)"
                       :native-locale "ja" :aliases '("nengo" "wareki") :default t)
   (make-calendar-spec :id "indian" :icu-id "indian" :label "Indian National (Śaka)"
                       :native-locale "hi" :aliases '("saka" "shaka") :default t)
   (make-calendar-spec :id "buddhist" :icu-id "buddhist" :label "Buddhist (Thai)"
                       :native-locale "th" :aliases '("thai" "be") :default t)
   (make-calendar-spec :id "persian" :icu-id "persian" :label "Persian (Solar Hijri)"
                       :native-locale "fa" :aliases '("jalali" "shamsi" "solar-hijri") :default t)
   (make-calendar-spec :id "ethiopic" :icu-id "ethiopic" :label "Ethiopic"
                       :native-locale "am" :aliases '("ethiopian" "amharic") :default t)
   (make-calendar-spec :id "coptic" :icu-id "coptic" :label "Coptic"
                       :native-locale "ar-EG" :aliases '("egyptian") :default nil)
   (make-calendar-spec :id "dangi" :icu-id "dangi" :label "Korean (Dangi)"
                       :native-locale "ko" :aliases '("korean") :default nil)
   (make-calendar-spec :id "roc" :icu-id "roc" :label "Minguo (ROC)"
                       :native-locale "zh-Hant-TW" :aliases '("minguo" "taiwan") :default nil))
  "Known calendar systems. DEFAULT T = shown when --calendars is omitted.")

(defun list-calendar-specs ()
  (copy-list *calendar-specs*))

(defun default-calendar-specs ()
  (remove-if-not #'calendar-spec-default *calendar-specs*))

(defun find-calendar-spec (name)
  "Resolve NAME (id or alias, case-insensitive) to a CALENDAR-SPEC."
  (let ((key (string-downcase (string-trim '(#\Space #\Tab) (string name)))))
    (or (find-if (lambda (spec)
                   (or (string= key (calendar-spec-id spec))
                       (member key (calendar-spec-aliases spec) :test #'string=)))
                 *calendar-specs*)
        (error 'cli:cli-usage-error
               :message (format nil "unknown calendar ~s; known: ~{~a~^, ~}"
                                name
                                (mapcar #'calendar-spec-id *calendar-specs*))))))

(defparameter *default-locale-tags*
  '("en" "zh-Hans" "ja" "ar" "he" "hi" "ru" "fr" "de" "es" "th" "fa")
  "Default BCP 47 tags — major languages + homes of the default calendars.")

(defparameter *locale-labels*
  '(("en" . "English")
    ("en-US" . "English (US)")
    ("en-GB" . "English (UK)")
    ("zh" . "Chinese")
    ("zh-Hans" . "Chinese (Simplified)")
    ("zh-Hant" . "Chinese (Traditional)")
    ("zh-Hant-TW" . "Chinese (Taiwan)")
    ("ja" . "Japanese")
    ("ko" . "Korean")
    ("ar" . "Arabic")
    ("ar-EG" . "Arabic (Egypt)")
    ("ar-SA" . "Arabic (Saudi Arabia)")
    ("he" . "Hebrew")
    ("hi" . "Hindi")
    ("ru" . "Russian")
    ("fr" . "French")
    ("de" . "German")
    ("es" . "Spanish")
    ("pt" . "Portuguese")
    ("pt-BR" . "Portuguese (Brazil)")
    ("th" . "Thai")
    ("fa" . "Persian")
    ("am" . "Amharic")
    ("it" . "Italian")
    ("nl" . "Dutch")
    ("pl" . "Polish")
    ("tr" . "Turkish")
    ("uk" . "Ukrainian")
    ("vi" . "Vietnamese")
    ("id" . "Indonesian")
    ("bn" . "Bengali")
    ("sw" . "Swahili")))

(defparameter *country-locales*
  ;; ISO 3166-1 alpha-2 → primary BCP 47 tag
  '(("US" . "en-US") ("GB" . "en-GB") ("IE" . "en-IE") ("AU" . "en-AU") ("CA" . "en-CA")
    ("NZ" . "en-NZ")
    ("FR" . "fr-FR") ("BE" . "fr-BE") ("CH" . "de-CH")
    ("DE" . "de-DE") ("AT" . "de-AT")
    ("ES" . "es-ES") ("MX" . "es-MX") ("AR" . "es-AR") ("CO" . "es-CO")
    ("IT" . "it-IT") ("PT" . "pt-PT") ("BR" . "pt-BR")
    ("NL" . "nl-NL") ("PL" . "pl-PL") ("SE" . "sv-SE") ("NO" . "nb-NO")
    ("DK" . "da-DK") ("FI" . "fi-FI")
    ("JP" . "ja-JP") ("CN" . "zh-Hans-CN") ("TW" . "zh-Hant-TW") ("HK" . "zh-Hant-HK")
    ("KR" . "ko-KR")
    ("IN" . "hi-IN") ("TH" . "th-TH") ("VN" . "vi-VN") ("ID" . "id-ID")
    ("MY" . "ms-MY") ("PH" . "en-PH")
    ("RU" . "ru-RU") ("UA" . "uk-UA") ("TR" . "tr-TR")
    ("IL" . "he-IL") ("SA" . "ar-SA") ("AE" . "ar-AE") ("EG" . "ar-EG")
    ("IR" . "fa-IR") ("ET" . "am-ET")
    ("GR" . "el-GR") ("CZ" . "cs-CZ") ("HU" . "hu-HU") ("RO" . "ro-RO")))

(defparameter *country-labels*
  '(("US" . "United States") ("GB" . "United Kingdom") ("IE" . "Ireland")
    ("AU" . "Australia") ("CA" . "Canada") ("NZ" . "New Zealand")
    ("FR" . "France") ("BE" . "Belgium") ("CH" . "Switzerland")
    ("DE" . "Germany") ("AT" . "Austria")
    ("ES" . "Spain") ("MX" . "Mexico") ("AR" . "Argentina") ("CO" . "Colombia")
    ("IT" . "Italy") ("PT" . "Portugal") ("BR" . "Brazil")
    ("NL" . "Netherlands") ("PL" . "Poland") ("SE" . "Sweden") ("NO" . "Norway")
    ("DK" . "Denmark") ("FI" . "Finland")
    ("JP" . "Japan") ("CN" . "China") ("TW" . "Taiwan") ("HK" . "Hong Kong")
    ("KR" . "South Korea")
    ("IN" . "India") ("TH" . "Thailand") ("VN" . "Vietnam") ("ID" . "Indonesia")
    ("MY" . "Malaysia") ("PH" . "Philippines")
    ("RU" . "Russia") ("UA" . "Ukraine") ("TR" . "Türkiye")
    ("IL" . "Israel") ("SA" . "Saudi Arabia") ("AE" . "United Arab Emirates")
    ("EG" . "Egypt") ("IR" . "Iran") ("ET" . "Ethiopia")
    ("GR" . "Greece") ("CZ" . "Czechia") ("HU" . "Hungary") ("RO" . "Romania")))

(defparameter *locale-countries*
  '(("en" . "US") ("en-US" . "US") ("en-GB" . "GB") ("en-IE" . "IE")
    ("en-AU" . "AU") ("en-CA" . "CA")
    ("zh" . "CN") ("zh-Hans" . "CN") ("zh-Hans-CN" . "CN")
    ("zh-Hant" . "TW") ("zh-Hant-TW" . "TW") ("zh-Hant-HK" . "HK")
    ("ja" . "JP") ("ja-JP" . "JP")
    ("ko" . "KR") ("ko-KR" . "KR")
    ("ar" . "SA") ("ar-SA" . "SA") ("ar-EG" . "EG") ("ar-AE" . "AE")
    ("he" . "IL") ("he-IL" . "IL")
    ("hi" . "IN") ("hi-IN" . "IN")
    ("ru" . "RU") ("ru-RU" . "RU")
    ("fr" . "FR") ("fr-FR" . "FR")
    ("de" . "DE") ("de-DE" . "DE")
    ("es" . "ES") ("es-ES" . "ES")
    ("pt" . "BR") ("pt-BR" . "BR") ("pt-PT" . "PT")
    ("th" . "TH") ("th-TH" . "TH")
    ("fa" . "IR") ("fa-IR" . "IR")
    ("am" . "ET") ("am-ET" . "ET")
    ("it" . "IT") ("nl" . "NL") ("pl" . "PL") ("tr" . "TR") ("uk" . "UA")
    ("vi" . "VN") ("id" . "ID") ("sv" . "SE") ("nb" . "NO") ("da" . "DK")
    ("fi" . "FI") ("el" . "GR") ("cs" . "CZ") ("hu" . "HU") ("ro" . "RO")
    ("ms" . "MY")))

(defparameter *locations*
  ;; name → IANA zone
  '(("tokyo" . "Asia/Tokyo")
    ("osaka" . "Asia/Tokyo")
    ("beijing" . "Asia/Shanghai")
    ("shanghai" . "Asia/Shanghai")
    ("hongkong" . "Asia/Hong_Kong")
    ("hong-kong" . "Asia/Hong_Kong")
    ("taipei" . "Asia/Taipei")
    ("seoul" . "Asia/Seoul")
    ("delhi" . "Asia/Kolkata")
    ("mumbai" . "Asia/Kolkata")
    ("kolkata" . "Asia/Kolkata")
    ("bangkok" . "Asia/Bangkok")
    ("jakarta" . "Asia/Jakarta")
    ("singapore" . "Asia/Singapore")
    ("jerusalem" . "Asia/Jerusalem")
    ("tel-aviv" . "Asia/Jerusalem")
    ("mecca" . "Asia/Riyadh")
    ("riyadh" . "Asia/Riyadh")
    ("tehran" . "Asia/Tehran")
    ("dubai" . "Asia/Dubai")
    ("cairo" . "Africa/Cairo")
    ("addis-ababa" . "Africa/Addis_Ababa")
    ("addis" . "Africa/Addis_Ababa")
    ("nairobi" . "Africa/Nairobi")
    ("johannesburg" . "Africa/Johannesburg")
    ("moscow" . "Europe/Moscow")
    ("kyiv" . "Europe/Kyiv")
    ("istanbul" . "Europe/Istanbul")
    ("athens" . "Europe/Athens")
    ("berlin" . "Europe/Berlin")
    ("paris" . "Europe/Paris")
    ("madrid" . "Europe/Madrid")
    ("rome" . "Europe/Rome")
    ("amsterdam" . "Europe/Amsterdam")
    ("london" . "Europe/London")
    ("dublin" . "Europe/Dublin")
    ("stockholm" . "Europe/Stockholm")
    ("helsinki" . "Europe/Helsinki")
    ("warsaw" . "Europe/Warsaw")
    ("prague" . "Europe/Prague")
    ("new-york" . "America/New_York")
    ("nyc" . "America/New_York")
    ("boston" . "America/New_York")
    ("chicago" . "America/Chicago")
    ("denver" . "America/Denver")
    ("los-angeles" . "America/Los_Angeles")
    ("la" . "America/Los_Angeles")
    ("san-francisco" . "America/Los_Angeles")
    ("mexico-city" . "America/Mexico_City")
    ("sao-paulo" . "America/Sao_Paulo")
    ("buenos-aires" . "America/Argentina/Buenos_Aires")
    ("toronto" . "America/Toronto")
    ("vancouver" . "America/Vancouver")
    ("sydney" . "Australia/Sydney")
    ("melbourne" . "Australia/Melbourne")
    ("auckland" . "Pacific/Auckland")
    ("utc" . "UTC")
    ("zulu" . "UTC")))

(defun %assoc-ci (key alist)
  (cdr (assoc key alist :test #'string-equal)))

(defun locale-label (tag)
  (or (%assoc-ci tag *locale-labels*)
      (%assoc-ci (locale-language tag) *locale-labels*)
      tag))

(defun country-label (code)
  (or (%assoc-ci (string-upcase code) *country-labels*)
      (string-upcase code)))

(defun country-locale (code)
  "Primary BCP 47 tag for an ISO country code, or NIL."
  (%assoc-ci (string-upcase code) *country-locales*))

(defun location-zone (name)
  "IANA zone for a city/place name, or NIL."
  (%assoc-ci (string-downcase (substitute #\- #\Space (string-trim '(#\Space) name)))
             *locations*))

(defun list-locations ()
  (sort (copy-list *locations*) #'string< :key #'car))

(defun locale-subtags (tag)
  (let* ((s (string tag))
         (base (subseq s 0 (or (position #\@ s) (length s))))
         (norm (substitute #\- #\_ base)))
    (remove "" (uiop:split-string norm :separator '(#\-)) :test #'string=)))

(defun locale-language (tag)
  (or (first (locale-subtags tag)) ""))

(defun locale-region (tag)
  "2-letter region subtag or NIL."
  (find-if (lambda (s)
             (and (= (length s) 2) (every #'alpha-char-p s)))
           (rest (locale-subtags tag))))

(defun english-locale-p (tag)
  (string-equal (locale-language tag) "en"))

(defun locale-with-calendar (locale calendar-icu-id)
  (format nil "~a@calendar=~a" locale calendar-icu-id))

(defun split-csv (string)
  (when (and string (plusp (length (string-trim '(#\Space #\Tab) string))))
    (remove ""
            (mapcar (lambda (p) (string-trim '(#\Space #\Tab) p))
                    (uiop:split-string string :separator '(#\,)))
            :test #'string=)))

(defun flatten-names (value)
  "VALUE is a string, list of strings, or NIL. Splits commas in each item."
  (cond
    ((null value) nil)
    ((stringp value) (split-csv value))
    ((listp value) (mapcan #'flatten-names value))
    (t (flatten-names (princ-to-string value)))))
