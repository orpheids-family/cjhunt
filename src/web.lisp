(in-package :cl-user)
(defpackage cjhunt.web
  (:use :cl
        :caveman2 :caveman2.exception
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

(defroute "/block" (&key |id|)
  (render-json (remove :tx (if |id| (getblock |id|) (getblock)) :key #'car)))

(defroute "/blockjoins" (&key (|id| (rpc "getbestblockhash")))
  (handler-case (render-json (blockjoins |id|))
    (error () (error 'caveman-exception :code 404))))

;;
;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
