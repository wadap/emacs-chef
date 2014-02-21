;; chef.el --- chef Minor Mode
;; -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2013 by wadap

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; version: 0.0.1
;; Author: wadap (shuichi.wada), me@shuichi.cc
;; URL: http://wadap.hatenablog.com/

(require 'cl)
(require 'anything)

(setq chef-env-path "default/")

(defgroup chef nil
  "Chef minor mode"
  :group 'convenience
  :prefix "chef-")

(define-minor-mode chef
  "Chef minor mode."
  :lighter " chef"
  :group 'chef
  (if cake
      (progn
        (setq minor-mode-map-alist
              (cons (cons 'chef chef-key-map)
                    minor-mode-map-alist))
        )
    nil))

  (if (fboundp 'define-global-minor-mode)
      (define-global-minor-mode 
        chef chef-maybe
        :group 'chef))
  )

(defun chef-maybe ()
  "What buffer `cake' prefers."
  (if (and (not (minibufferp (current-buffer)))
           (chef-find-path))
      (cake 1)
    nil))

(defun chef-set-default-keymap ()
  "set default key map"
  (interactive)
  (setq chef-key-map
        (let ((map (make-sparse-keymap)))
          (define-key map "\C-c a" 'chef-switch-to-attribute)
          map)))

(defun chef-switch-to-attribute ()
  "Switch to attribute."
  (interactive)
  (chef-switch-to-file (concat (chef-find-path) "/attributes/default.rb"))
)

(defun chef-switch-to-template ()
  "Switch to template."
  (interactive)
  (if (re-search-backward "template[\t\s]+\".+/\\(.+\\)\"[\t\s]+do")
      (if (file-exists-p (concat (chef-find-path) "/templates/" chef-env-path (match-string 1) ".erb" ))
          (find-file (concat (chef-find-path) "/templates/" chef-env-path (match-string 1)  ".erb"))
          (chef-switch-to-file (concat (chef-find-path) "/templates/" chef-env-path (match-string 1) ".erb"))
        )
    )
  (if (string-match "source\s+\"\\(.+\.erb\\)\"" (chef-get-current-line))
      (if (file-exists-p (concat (chef-find-path) "/templates/" chef-env-path(match-string 1 (chef-get-current-line))))
          (find-file (concat (chef-find-path) "/templates/" chef-env-path (match-string 1 (chef-get-current-line))))
        (chef-switch-to-file (concat (chef-find-path) "/templates/" chef-env-path (match-string 1 (chef-get-current-line))))
        )
    )
  )

(defun chef-switch-to-cookbookfile ()
  "Switch to cookbook_file"
  (interactive)
  (if (re-search-backward "cookbook_file[\t\s]*[\"'].+/\\(.+\\)[\"'][\t\s]*do")
      (if (file-exists-p (concat (chef-find-path) "/files/" chef-env-path (match-string 1)))
          (find-file (concat (chef-find-path) "/files/" chef-env-path (match-string 1)))
        (chef-switch-to-file (concat (chef-find-path) "/files/" chef-env-path (match-string 1)))
          )
      )
  )

(defun chef-switch-to-recipe ()
  "Switch to default recipe"
  (interactive)
  (chef-switch-to-file (concat (chef-find-path) "/recipes/default.rb"))
  )

(defun chef-switch-to-include-recipe ()
  "Switch to include recipe"
  (interactive)
  (if (string-match "include_recipe[\s\t]+['\"]\\(.+\\)::\\(.+\\)['\"]" (chef-get-current-line))
      (chef-switch-to-file (concat (chef-find-path) "../" (match-string 1 (chef-get-current-line)) "/recipes/" (match-string 2 (chef-get-current-line)) ".rb"))
    )
  )

(defun chef-switch-to-metadata ()
  "Switch to metadata"
  (interactive)
  (if (file-exists-p (concat (chef-find-path) "/metadata.rb"))
      (find-file (concat (chef-find-path) "/metadata.rb"))
    (chef-switch-to-file (concat (chef-find-path) "/metadata.rb"))
    )
  )

(defun chef-switch-to-readme ()
  "Switch to readme"
  (interactive)
  (if (file-exists-p (concat (chef-find-path) "/README.md"))
      (find-file (concat (chef-find-path) "/README.md"))
    (chef-switch-to-file (concat (chef-find-path) "/README.md"))
    )
  )

(defun chef-open-cookbook () 
  (interactive)
  (anything-other-buffer(anything-c-source-chef) nil))

(defun anything-c-source-chef()
  (interactive)
  (message (format "%s" (chef-find-path)))
  '((name . "Chef Files")
    (message (formt "%s" (chef-find-path)))
    (candidates . (lambda() (cake-get-recuresive-path-list "~/work/solo/cookbooks/apache")))
    (candidates-in-buffer)
    (type . file)
    ))

(defun cake-get-recuresive-path-list (file-list)
  "Get file path list recuresively."
  (let ((path-list nil))
    (unless (listp file-list)
      (setq file-list (list file-list)))
    (loop for x
          in file-list
          do (if (file-directory-p x)
                 (setq path-list
                       (append
                        (cake-get-recuresive-path-list
                         (remove-if
                          (lambda(y) (string-match "\\.$\\|\\.svn" y)) (directory-files x t)))
                        path-list))
               (setq path-list (push x path-list))))
    path-list))

(defun chef-get-cookbooks () 
  "Find Other Cookbook List"
  (let ((cookbooks (list)))
    (loop for file in (directory-files (concat (chef-find-path) "../" )) do
          (if (string-match "^[a-z0-9]+" file)
              (if (file-directory-p (concat (chef-find-path) "../" file))
                  (push file cookbooks)
                )
            )
          )
    (reverse cookbooks))
  )

(defun chef-get-cookbook-dirs ()
  "Find Other Cookbook Path List"
  (let ((cookbooks (list)))
    (loop for dir in (chef-get-cookbooks) do
          (push (concat (chef-find-path) "../" dir) cookbooks)
          )
    (reverse cookbooks))
  )

(defun chef-get-recursive-path-list (file-list)
  "Get file path list recuresively."
  (let ((path-list nil))
    (unless (listp file-list)
      (setq file-list (list file-list)))
    (loop for x in file-list do 
          (if (file-directory-p x)
                 (setq path-list
                       (append
                        (chef-get-recursive-path-list
                         (remove-if
                          (lambda(y) (string-match "\\.$\\|\\.svn" y)) (directory-files x t)))
                        path-list))
               (setq path-list (push x path-list))
               )
          )
    (reverse path-list))
  )

(defun chef-find-path ()
  "Find Chef Directory"
  (let ((current-dir default-directory))
  (loop with count = 0
        until (file-exists-p (concat current-dir "metadata.rb"))
        if (= count 5)
        do (return nil)
        else
        do (incf count)
        (setq current-dir (expand-file-name (concat current-dir "../")))
        finally return current-dir))
  )

(defun chef-switch-to-file (file-path)
  "Switch to file."
  (if (file-exists-p file-path)
      (find-file file-path)
    (if (y-or-n-p "Make new File?")
        (find-file file-path)
      (message (format "Can't find %s" file-path)))))

(defun chef-get-current-line ()
  "Get current line."
  (thing-at-point 'line))

(provide 'chef)

;;;; end
