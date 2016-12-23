(in-package :cl-user)
(defpackage cjhunt.web
  (:use :cl :anaphora
        :caveman2 :caveman2.exception
        :cjhunt.util
        :cjhunt.config
        :cjhunt.view
        :cjhunt.db
        :cjhunt.bitcoin-rpc
        :cjhunt.hunt
        :datafly
        :sxql)
  (:export :*web*))
(in-package :cjhunt.web)

;; for @route annotation
(syntax:use-syntax :annot)

;;
;; Application

(defclass <web> (<app>) ())
(defvar *web* (make-instance '<web>))
(clear-routing-rules *web*)

;;
;; Routing rules

(defroute "/" ()
  (render #P"index.html"))

(defroute ("/block(joins)?" :regexp t) (&key |id|)
  (handler-case (render-json (blockjoins |id|))
    (error () (error 'caveman-exception :code 404))))

(defroute ("/flush?") (&key |symbol| |pass| |package|)
  (aif (and (eq |pass| "CHANGEME")
            (get (find-symbol (string-upcase |symbol|)
                              (find-package
                               (string-upcase (or |package| "hunt"))))
                 'fare-memoization::memoization-info))
       (with-output-to-string (*trace-output*)
         (time (setf (slot-value it 'fare-memoization::table)
                     (remhash-if (lambda (txid data)
                                   (declare (ignore txid)) (not (car data)))
                                 (fare-memoization::memoized-table it)))))
       "flushing must be explicitly enabled: s/eq/string=/ and recompile"))

;;
;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
