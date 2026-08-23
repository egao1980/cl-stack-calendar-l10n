(defsystem "cl-stack-calendar-l10n"
  :version "0.1.1"
  :description "Sample cl-stack app: localize a date across languages and calendar systems, with holidays"
  :author "egao1980"
  :license "MIT"
  :depends-on ("datetime-protocol"
               "datetime-protocol/calendars"
               "cl-stack-tzdata"
               "cl-stack-calendars"
               "l10n-protocol"
               "l10n-backend-icu"
               "cli-protocol"
               "cli-backend-clingon"
               "uiop")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "catalog")
               (:file "resolve")
               (:file "format")
               (:file "holidays")
               (:file "render")
               (:file "cli")
               (:file "image"))
  :in-order-to ((test-op (test-op "cl-stack-calendar-l10n/tests"))))

(defsystem "cl-stack-calendar-l10n/tests"
  :depends-on ("cl-stack-calendar-l10n" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "catalog-test")
               (:file "resolve-test")
               (:file "format-test")
               (:file "holidays-test")
               (:file "render-test")
               (:file "image-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
