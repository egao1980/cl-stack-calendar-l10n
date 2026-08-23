;;;; Dump a self-contained SBCL executable + ICU natives + tz/holiday data.
;;;;
;;;;   DUMP_DIR=dist/calendar-l10n-darwin-arm64 ros -l scripts/dump-image.lisp -q
;;;;
;;;; Layout:
;;;;   $DUMP_DIR/calendar-l10n[.exe]
;;;;   $DUMP_DIR/lib/                 ICU shared libs
;;;;   $DUMP_DIR/data/tzdata/         cl-stack-tzdata data/
;;;;   $DUMP_DIR/data/countries/      cl-stack-calendars country sexps

#-sbcl (error "scripts/dump-image.lisp requires SBCL (save-lisp-and-die)")

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        (uiop:quit 1)))

(sb-ext:disable-debugger)

(format t "~&; dump-image: loading cl-stack-calendar-l10n~%")
(asdf:load-system "cl-stack-calendar-l10n")

(defun %dump-dir ()
  (let ((raw (or (uiop:getenv "DUMP_DIR") "dist/calendar-l10n")))
    (uiop:ensure-directory-pathname
     (uiop:ensure-absolute-pathname raw (uiop:getcwd)))))

(defun %exe-name ()
  #+windows "calendar-l10n.exe"
  #-windows "calendar-l10n")

(defun %copy-file (from to)
  (ensure-directories-exist to)
  (uiop:copy-file from to)
  to)

(defun %copy-tree (from to)
  (let ((from (uiop:ensure-directory-pathname from))
        (to (uiop:ensure-directory-pathname to)))
    (ensure-directories-exist to)
    (dolist (file (uiop:directory-files from))
      (%copy-file file (merge-pathnames (file-namestring file) to)))
    (dolist (sub (uiop:subdirectories from))
      (let ((name (car (last (pathname-directory sub)))))
        (when name
          (%copy-tree sub (merge-pathnames
                           (make-pathname :directory (list :relative name))
                           to)))))
    to))

(defun %first-icu-dir ()
  (let ((fn (find-symbol "%NATIVE-SEARCH-DIRS" "CL-STACK-ICU")))
    (unless (and fn (fboundp fn))
      (error "cl-stack-icu:%native-search-dirs missing"))
    (or (find-if (lambda (dir)
                   (and dir
                        (uiop:directory-exists-p dir)
                        (or (probe-file (merge-pathnames "libicuuc.dylib" dir))
                            (probe-file (merge-pathnames "libicuuc.so" dir))
                            (probe-file (merge-pathnames "libicuuc.so.78" dir))
                            (probe-file (merge-pathnames "icuuc78.dll" dir)))))
                 (funcall fn))
        (error "no ICU native directory found (install cl-stack-icu overlay)"))))

(defun %bundle (dump-dir)
  (let ((lib (merge-pathnames "lib/" dump-dir))
        (tz (merge-pathnames "data/tzdata/" dump-dir))
        (cc (merge-pathnames "data/countries/" dump-dir))
        (icu (%first-icu-dir))
        (tz-src (uiop:symbol-call :cl-stack-tzdata "TZDATA-ROOT"))
        (cc-src (symbol-value
                 (find-symbol "*COUNTRIES-DATA-DIRECTORY*" "CL-STACK-CALENDARS"))))
    (format t "~&; bundling ICU from ~A~%" icu)
    (%copy-tree icu lib)
    #+windows
    (dolist (file (uiop:directory-files lib))
      (when (string-equal (pathname-type file) "dll")
        (%copy-file file (merge-pathnames (file-namestring file) dump-dir))))
    (format t "~&; bundling tzdata from ~A~%" tz-src)
    (%copy-tree tz-src tz)
    (format t "~&; bundling country calendars from ~A~%" cc-src)
    (%copy-tree cc-src cc)
    (values lib tz cc)))

(defun %forget-cffi-reload ()
  "Don't let CFFI reopen dump-time absolute paths; image-main reloads from lib/."
  (let ((cffi (find-package "CFFI")))
    (when cffi
      (let ((close (find-symbol "CLOSE-FOREIGN-LIBRARIES" cffi)))
        (when (and close (fboundp close))
          (funcall close)))))
  ;; Drop Roswell/CFFI/QL init hooks — a standalone binary must not
  ;; re-enter ASDF/QL just because the dump host had a source registry.
  (setf sb-ext:*init-hooks*
        (list 'cl-stack-calendar-l10n:configure-bundled-paths)))

(defun %freeze-asdf-for-dump ()
  "Forget the dump machine's ASDF/qlot registry so restore cannot recompile."
  (when (find-package "ASDF")
    (ignore-errors
      (dolist (sys (uiop:symbol-call :asdf "ALREADY-LOADED-SYSTEMS"))
        (ignore-errors (uiop:symbol-call :asdf "REGISTER-IMMUTABLE-SYSTEM" sys))))
    (let ((cr (find-symbol "*CENTRAL-REGISTRY*" "ASDF")))
      (when cr (setf (symbol-value cr) nil)))
    (ignore-errors (uiop:symbol-call :asdf "CLEAR-SOURCE-REGISTRY"))
    (ignore-errors (uiop:symbol-call :asdf "CLEAR-OUTPUT-TRANSLATIONS"))
    (ignore-errors (uiop:symbol-call :asdf "CLEAR-CONFIGURATION")))
  (setf (uiop:getenv "CL_SOURCE_REGISTRY")
        "(:source-registry :ignore-inherited-configuration)"))

(let* ((dump-dir (%dump-dir))
       (exe (merge-pathnames (%exe-name) dump-dir)))
  (ensure-directories-exist dump-dir)
  (%bundle dump-dir)
  (setf uiop:*image-entry-point* #'cl-stack-calendar-l10n:image-main)
  (uiop:register-image-restore-hook 'cl-stack-calendar-l10n:configure-bundled-paths)
  (%forget-cffi-reload)
  (%freeze-asdf-for-dump)
  (format t "~&; dumping ~A~%" exe)
  (finish-output)
  (uiop:dump-image exe :executable t))
