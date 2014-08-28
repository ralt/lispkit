(in-package :lispkit)


(defparameter *default-page*
  "http://www.this-page-intentionally-left-blank.org/")

(djula:add-template-directory (asdf:system-relative-pathname :lispkit "templates/"))
(defvar +helppage+ (djula:compile-template* "helppage.dtl"))
(defvar +command-info+ (djula:compile-template* "command-info.dtl"))

(defun load-ui-from-file (path)
  (if (probe-file path)
      (let ((builder (gtk:gtk-builder-new)))
        (gtk:gtk-builder-add-from-file builder (namestring path))
        builder)
      (error (format nil "non existent path: ~a" path))))

(defun main (&optional (destroy? nil) (ui-file (asdf:system-relative-pathname :lispkit "main.ui")))
  "Main exists separately from do-main so that during development we
  can easily separate killing the main gtk loop from stopping and
  starting applications within that main loop"
  (within-main-loop
    (let* ((ui      (load-ui-from-file ui-file))
           (window  (gtk:gtk-builder-get-object ui "mainwindow"))
           (frame   (gtk:gtk-builder-get-object ui "scrolledwindow"))
           (entry   (gtk:gtk-builder-get-object ui "entry_box"))
           (view    (make-webview))
           (nb      (gtk:gtk-builder-get-object ui "webviewcontainer"))
           (browser (make-browser ui view)))
      (gtk-notebook-set-show-tabs nb nil)
      (gtk-container-add frame view)
      (g-signal-connect window "key_press_event"
                        (make-key-dispatcher browser))
      (g-signal-connect nb "switch-page"
                        (make-page-listener browser))
      (when destroy?
        (g-signal-connect window "destroy"
                          (lambda (widget)
                            (declare (ignore widget))
                            (leave-gtk-main))))
      (load-url *default-page* browser)
      (gtk-widget-hide entry)
      ;; TODO - Add error handling to this.
      (load-rc-file)
      (dolist (widget (list window frame view))
        (gtk-widget-show widget)))))

(defun do-main (&rest args)
  "The main entry point when running as an executable. This should not
   be run directly but only indirectly when an image has been built."
  (declare (ignore args))
  (main t #P"/usr/share/lispkit/main.ui")
  (join-gtk-main))
