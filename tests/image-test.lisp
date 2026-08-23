(in-package #:cl-stack-calendar-l10n/tests)

(deftest configure-bundled-paths-noop-without-bundle
  (ng (configure-bundled-paths (uiop:temporary-directory))))

(deftest bundle-root-is-a-directory-or-nil
  (let ((root (bundle-root)))
    (ok (or (null root) (uiop:directory-pathname-p root)))))
