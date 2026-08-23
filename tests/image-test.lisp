(in-package #:cl-stack-calendar-l10n/tests)

(deftest configure-bundled-paths-noop-without-bundle
  (ng (configure-bundled-paths (uiop:temporary-directory))))

(deftest bundle-root-is-a-directory-or-nil
  (let ((root (bundle-root)))
    (ok (or (null root) (uiop:directory-pathname-p root)))))

(deftest configure-bundled-paths-data-zip
  (uiop:with-temporary-file (:pathname tmp :keep t)
    (delete-file tmp)
    (let* ((root (uiop:ensure-directory-pathname tmp))
           (zip (merge-pathnames "data.zip" root)))
      (unwind-protect
           (progn
             (ensure-directories-exist root)
             (sp:write-zip-file
              zip '(("countries/index.sexp" "((\"ZZ\" \"Zedland\" 0))")
                    ("countries/ZZ.sexp" "(:code \"ZZ\" :name \"Zedland\" :days ())")))
             (ok (configure-bundled-paths root))
             (ok (sp:zip-filesystem-p (sp:path-filesystem (cal:data-root))))
             (ok (string= (cal:country-calendar-code (cal:country-calendar "ZZ")) "ZZ")))
        (cal:set-data-root nil)
        (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore)
        (sp:clear-zip-filesystem-cache))))))
