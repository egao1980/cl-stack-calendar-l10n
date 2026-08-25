;;;; Dump a self-contained SBCL executable + ICU natives + tz/holiday data.
;;;;
;;;;   DUMP_DIR=dist/calendar-l10n-darwin-arm64 ros -l scripts/dump-image.lisp -q
;;;;
;;;; Layout:
;;;;   $DUMP_DIR/calendar-l10n[.exe]
;;;;   $DUMP_DIR/lib/                 ICU shared libs
;;;;   $DUMP_DIR/data.zip             cl-stack-calendars sexp tree (zip://)
;;;;   $DUMP_DIR/data/tzdata/         cl-stack-tzdata data/

#-sbcl (error "scripts/dump-image.lisp requires SBCL (save-lisp-and-die)")

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        (uiop:quit 1)))

(sb-ext:disable-debugger)

(setf asdf:*compile-file-failure-behaviour* :warn)

(defun %call-with-dump-muffles (fn)
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql #'continue))
    (funcall fn))
  #-sbcl
  (funcall fn))

(defun %maybe-wire-cl-repo ()
  "Same bootstrap as canned cl-repo CI so OCI-installed deps are visible.
   No-op when dumping from a workspace that already has siblings on the registry."
  (when (asdf:find-system "cl-repository-client" nil)
    (asdf:load-system "cl-repository-client")
    (when (find-package "CL-REPOSITORY-CLIENT/ASDF-INTEGRATION")
      (uiop:symbol-call :cl-repository-client/asdf-integration
                        "CONFIGURE-ASDF-SOURCE-REGISTRY")
      (uiop:symbol-call :cl-repository-client/asdf-integration
                        "LOAD-SYSTEM-INIT-FILES"))))

(format t "~&; dump-image: loading cl-stack-calendar-l10n~%")
(%maybe-wire-cl-repo)
(%call-with-dump-muffles
 (lambda () (asdf:load-system "cl-stack-calendar-l10n")))

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

(defun %copy-needed-icu (from to)
  "Copy only the sonames load-icu actually opens — not the unversioned
   aliases (those doubled icudata from 32MB to 64MB).

   %find-lib returns a truename. On a dev machine that is often a Homebrew
   libicudata.78.3.dylib behind a libicudata.78.dylib symlink; CFFI will
   not look for the 78.3 basename, so we install under the first candidate
   name (%lib-candidates), not the resolved filename."
  (ensure-directories-exist to)
  (let ((find-lib (find-symbol "%FIND-LIB" "CL-STACK-ICU"))
        (candidates (find-symbol "%LIB-CANDIDATES" "CL-STACK-ICU"))
        (find-mf2 (find-symbol "%FIND-MF2-LIB" "CL-STACK-ICU"))
        (copied '()))
    (unless (and find-lib (fboundp find-lib))
      (error "cl-stack-icu:%find-lib missing"))
    (dolist (which '(:data :uc :i18n))
      (let ((src (funcall find-lib from which)))
        (unless src
          (error "missing ICU ~A in ~A" which from))
        (let* ((names (and candidates (fboundp candidates)
                           (funcall candidates which)))
               (name (or (first names) (file-namestring (pathname src)))))
          (%copy-file (pathname src) (merge-pathnames name to))
          (push name copied))))
    (let ((mf2 (or (and find-mf2 (fboundp find-mf2) (funcall find-mf2 from))
                   (find-if #'probe-file
                            (mapcar (lambda (n) (merge-pathnames n from))
                                    '("libcl_stack_icu_mf2.dylib"
                                      "libcl_stack_icu_mf2.so"
                                      "cl_stack_icu_mf2.dll"))))))
      (when mf2
        (let ((name (file-namestring (pathname mf2))))
          (%copy-file (pathname mf2) (merge-pathnames name to))
          (push name copied))))
    (format t "~&; ICU files: ~{~A~^, ~}~%" (nreverse copied))
    to))

(defun %bundle (dump-dir)
  (let ((lib (merge-pathnames "lib/" dump-dir))
        (tz (merge-pathnames "data/tzdata/" dump-dir))
        (data-zip (merge-pathnames "data.zip" dump-dir))
        (icu (%first-icu-dir))
        (tz-src (uiop:symbol-call :cl-stack-tzdata "TZDATA-ROOT"))
        (cal-src (uiop:symbol-call :cl-stack-calendars "DEFAULT-DATA-ROOT")))
    (format t "~&; bundling ICU from ~A~%" icu)
    (%copy-needed-icu icu lib)
    (format t "~&; bundling tzdata from ~A~%" tz-src)
    (%copy-tree tz-src tz)
    (format t "~&; bundling calendar sexps → ~A~%" data-zip)
    (uiop:symbol-call :cl-stack-calendars "WRITE-DATA-ZIP" data-zip cal-src)
    (values lib tz data-zip)))

(defun %shared-objects-cell ()
  (or (find-symbol "*SHARED-OBJECTS*" "SB-SYS")
      (find-symbol "*SHARED-OBJECTS*" "SB-ALIEN")))

(defun %forget-host-foreign-objects ()
  "SBCL FOREIGN-REINIT reopens dump-time DLL/so paths *before* any Lisp hook.
   Close CFFI, mark/drop those objects, and keep only our restore hook so a
   foreign machine loads ICU from $DUMP_DIR/lib/ (CI smoke hid this: the
   runner still had C:\\Users\\runneradmin\\...\\cl-stack-icu\\...\\native)."
  (let ((cffi (find-package "CFFI")))
    (when cffi
      (let ((close (find-symbol "CLOSE-FOREIGN-LIBRARIES" cffi)))
        (when (and close (fboundp close))
          (funcall close)))))
  (let ((cell (%shared-objects-cell)))
    (when cell
      (dolist (obj (copy-list (symbol-value cell)))
        (ignore-errors
          (setf (sb-alien::shared-object-dont-save obj) t))
        (let ((path (ignore-errors (sb-alien::shared-object-pathname obj))))
          (when path
            (ignore-errors (sb-alien:unload-shared-object path)))))
      (setf (symbol-value cell) nil)
      (format t "~&; cleared SBCL shared-objects~%")))
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
  (%forget-host-foreign-objects)
  (%freeze-asdf-for-dump)
  (format t "~&; dumping ~A~%" exe)
  (finish-output)
  ;; Leave the SBCL core uncompressed. zlib-packing it *grows* the
  ;; release tar.gz/zip: gzip/zstd already crush a raw core (~97MB →
  ;; ~22MB) and then cannot recompress a zlib core. The 50MB archive
  ;; fat was duplicate ICU sonames, not an uncompressed Lisp image.
  (uiop:dump-image exe :executable t))
