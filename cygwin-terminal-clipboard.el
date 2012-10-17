;;; cygwin-terminal-clipboard.el -- Terminal Emacs integration with Cygwin's Windows Clipboard

;; Copyright (C) 2012 mld75

;; Author: mld75
;; Keywords: clipboard cygwin killring

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Simple global minor mode providing integration of emacs running under cygwin
;; in terminal mode with the windows clipboard.
;;
;; ## Basic usage
;;
;; As simple as
;;
;;     (require 'cygwin-terminal-clipboard)
;;     (cygwin-terminal-clipboard-mode)
;;
;;; Code:

(define-minor-mode cygwin-terminal-clipboard-mode
  "Toggle Cygwin Terminal Clipboard mode.

Interfaces under Cygwin in Terminal Mode (-nw) with the
Windows Clipboard via /dev/clipboard.

Mode will only start in case we are under cygwin and we
are not under a window system."
  :global t
  (ctcm/init-mode))

(defconst ctcm/cygwin-clipboard-file "/dev/clipboard")

(defun ctcm/init-mode ()
  (if cygwin-terminal-clipboard-mode
      (ctcm/start-mode)
    (ctcm/stop-mode)))

(defun ctcm/start-mode ()
  "Only starting in case we are under cygwin and in a window system."
  (cond
   ((and (eq system-type 'cygwin) (not window-system))
    (setq interprogram-cut-function 'ctcm/cut
          interprogram-paste-function 'ctcm/paste)

    (message "cygwin-terminal-clipboard-mode: enabled."))
   (t (message "cygwin-terminal-clipboard-mode: Not running under cygwin or not in terminal."))))

(defun ctcm/stop-mode ()
    (setq interprogram-cut-function nil
          interprogram-paste-function nil)
  (message "cygwin-terminal-clipboard-mode: disabled."))

(defun ctcm/cut (text)
  (interactive)
  (with-temp-buffer
    (insert text)
    (write-region nil nil ctcm/cygwin-clipboard-file nil 'nomessage)))

(defun ctcm/paste ()
"Returns either Cygwin's clipboard contents or nil in case those are already on top of the kill ring.

Is coded according to protocol defined in `interprogram-paste-function'.

This function is reentrant by setting `interprogram-paste-function' to nil
for recursive calls."
  (when interprogram-paste-function
    (unwind-protect
        (progn
          (setq interprogram-paste-function nil)
          (ctcm//paste))
      (setq interprogram-paste-function 'ctcm/paste))))

(defun ctcm//paste ()
"Returns either Cygwin's clipboard contents or nil in case those are already on top of the kill ring.

Is coded according to protocol defined in `interprogram-paste-function'.

NOT reentrant."
  (with-temp-buffer
    (let ((cygwin-clipboard (or (ctcm//get-clipboard-contents) ""))
          (top-kill-ring (substring-no-properties (or (current-kill 0 t) ""))))
      (if (string= cygwin-clipboard top-kill-ring)
          nil
        cygwin-clipboard))))

(defun ctcm//get-clipboard-contents ()
  (with-temp-buffer
    (insert-file-contents ctcm/cygwin-clipboard-file)
    (buffer-string)))

(provide 'cygwin-terminal-clipboard)

;;; cygwin-term-clipboard.el ends here
