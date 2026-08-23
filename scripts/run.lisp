;;;; ros -l scripts/run.lisp -- --datetime 2024-07-04 --timezone Asia/Tokyo

(require :asdf)
(asdf:load-system "cl-stack-calendar-l10n")
(cl-stack-calendar-l10n:main)
