(in-package #:cl-stack-calendar-l10n)

(defun make-app ()
  (cli:make-command
   :name "calendar-l10n"
   :description "Show a date localized across languages and calendar systems."
   :version "0.1.0"
   :options
   (list
    (cli:make-option
     :name "datetime" :short #\d :long "datetime" :kind :string :key :datetime
     :help "ISO date (YYYY-MM-DD) or RFC 3339 datetime. Default: now.")
    (cli:make-option
     :name "timezone" :short #\z :long "timezone" :kind :string :key :timezone
     :help "IANA zone or ±HH:MM. Default: local ($TZ / /etc/localtime).")
    (cli:make-option
     :name "location" :short #\L :long "location" :kind :string :key :location
     :help "City (tokyo, london, mecca, …) or IANA zone. Sets timezone.")
    (cli:make-option
     :name "locales" :short #\l :long "locales" :kind :string :key :locales
     :help "Comma-separated BCP 47 tags (ja,fr,ar). Default: major languages.")
    (cli:make-option
     :name "countries" :short #\c :long "countries" :kind :string :key :countries
     :help "ISO country codes (JP,IL,TH). Adds locales + holiday calendars.")
    (cli:make-option
     :name "calendars" :short #\C :long "calendars" :kind :string :key :calendars
     :help "Calendar systems (gregorian,islamic,hebrew,…). Default: major civil/religious.")
    (cli:make-option
     :name "style" :short #\s :long "style" :kind :string :key :style :default "full"
     :help "Date style: full, long, medium, short.")
    (cli:make-option
     :name "no-english" :long "no-english" :kind :flag :key :no-english
     :help "Skip English parallel lines.")
    (cli:make-option
     :name "no-holidays" :long "no-holidays" :kind :flag :key :no-holidays
     :help "Skip the holiday section.")
    (cli:make-option
     :name "list" :long "list" :kind :flag :key :list
     :help "Print known calendars, locales, countries, locations and exit."))
   :handler
   (lambda (opts free)
     (declare (ignore free))
     (if (cli:get-option opts :list)
         (print-catalog)
         (report-and-print
          :datetime (cli:get-option opts :datetime)
          :timezone (cli:get-option opts :timezone)
          :location (cli:get-option opts :location)
          :locales (cli:get-option opts :locales)
          :countries (cli:get-option opts :countries)
          :calendars (cli:get-option opts :calendars)
          :style (parse-style (cli:get-option opts :style "full"))
          :english (not (cli:get-option opts :no-english))
          :holidays (not (cli:get-option opts :no-holidays)))))))

(defun main (&optional argv)
  (cli:main (make-app)
            :argv (or argv (uiop:command-line-arguments))))
