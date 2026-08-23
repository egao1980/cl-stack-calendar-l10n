(in-package #:cl-stack-calendar-l10n)

;;;; Relocate ICU natives + tzdata / country corpora next to a dumped
;;;; SBCL executable (see scripts/dump-image.lisp).

(defun bundle-root ()
  "Directory containing the running executable (dumped image) or NIL."
  (let ((p (or #+sbcl (and (boundp 'sb-ext:*runtime-pathname*)
                           sb-ext:*runtime-pathname*)
               (ignore-errors (uiop:argv0)))))
    (when (and p (or (pathnamep p) (plusp (length (string p)))))
      (uiop:pathname-directory-pathname
       (uiop:ensure-absolute-pathname p (uiop:getcwd))))))

(defun %bundle-subdir (root relative)
  (when root
    (let ((p (merge-pathnames relative (uiop:ensure-directory-pathname root))))
      (when (probe-file p) (uiop:ensure-directory-pathname p)))))

(defun %bundle-file (root relative)
  (when root
    (let ((p (merge-pathnames relative (uiop:ensure-directory-pathname root))))
      (when (probe-file p) p))))

(defun %prepend-env (name dir)
  (let* ((old (uiop:getenv name))
         (dir (string-right-trim "/\\" (namestring dir)))
         (sep #+windows ";" #-windows ":"))
    (setf (uiop:getenv name)
          (if (and old (plusp (length old)))
              (concatenate 'string dir sep old)
              dir))))

(defun %isolate-asdf ()
  "Stop a dumped image from recompiling workspace/QL systems via inherited CL_SOURCE_REGISTRY."
  (setf (uiop:getenv "CL_SOURCE_REGISTRY")
        "(:source-registry :ignore-inherited-configuration)")
  (when (find-package "ASDF")
    (let ((cr (find-symbol "*CENTRAL-REGISTRY*" "ASDF")))
      (when cr (setf (symbol-value cr) nil)))
    (ignore-errors (uiop:symbol-call :asdf "CLEAR-SOURCE-REGISTRY"))
    (ignore-errors (uiop:symbol-call :asdf "CLEAR-OUTPUT-TRANSLATIONS"))
    (ignore-errors (uiop:symbol-call :asdf "CLEAR-CONFIGURATION"))
    (ignore-errors (uiop:symbol-call :asdf "INITIALIZE-SOURCE-REGISTRY"))))

(defun %retarget-icu (lib-dir)
  (setf (uiop:getenv "CL_STACK_ICU_NATIVE") (uiop:native-namestring lib-dir))
  #+windows (%prepend-env "PATH" lib-dir)
  #+linux (%prepend-env "LD_LIBRARY_PATH" lib-dir)
  #+darwin (%prepend-env "DYLD_LIBRARY_PATH" lib-dir)
  (let ((cffi (find-package "CFFI")))
    (when cffi
      (let ((var (find-symbol "*FOREIGN-LIBRARY-DIRECTORIES*" cffi)))
        (when var
          (pushnew (uiop:ensure-directory-pathname lib-dir)
                   (symbol-value var) :test #'equal)))))
  (when (find-package "CL-STACK-ICU")
    (setf (symbol-value (find-symbol "*ICU-LOADED*" "CL-STACK-ICU")) nil)
    (uiop:symbol-call :cl-stack-icu "LOAD-ICU")))

(defun %retarget-tzdata (tz-dir)
  (when (find-package "CL-STACK-TZDATA")
    (setf (symbol-value (find-symbol "*TZDATA-REPOSITORY*" "CL-STACK-TZDATA"))
          (uiop:symbol-call :cl-stack-tzdata "MAKE-TZDATA-REPOSITORY" :root tz-dir))
    (setf dt:*tz-repository* nil)))

(defun %retarget-countries (cc-dir)
  (setf cal::*countries-data-directory* (uiop:ensure-directory-pathname cc-dir))
  (cal:clear-country-calendar-cache))

(defun %retarget-calendars (designator)
  "Point cl-stack-calendars at a directory or client-app data.zip."
  (cal:set-data-root designator))

(defun configure-bundled-paths (&optional (root (bundle-root)))
  "If ROOT looks like a dump bundle (lib/, data.zip, data/), retarget search paths.
   Prefer data.zip (zip:// VFS) over an unpacked data/countries/ tree.
   No-op when running from source."
  (let ((lib (%bundle-subdir root "lib/"))
        (tz (%bundle-subdir root "data/tzdata/"))
        (data-zip (%bundle-file root "data.zip"))
        (cc (%bundle-subdir root "data/countries/")))
    (when (or lib tz data-zip cc) (%isolate-asdf))
    (when lib (%retarget-icu lib))
    (when tz (%retarget-tzdata tz))
    (cond (data-zip (%retarget-calendars data-zip))
          (cc (%retarget-countries cc)))
    (and (or lib tz data-zip cc) t)))

(defun image-main ()
  "Toplevel for a dumped executable."
  (handler-bind ((error (lambda (c)
                          (format *error-output* "~&~A~%" c)
                          (uiop:quit 1))))
    (configure-bundled-paths)
    (main)))
