;; Copyright (C) 1995, 1997, 1998, 2001, 2002, 2003, 2004,
;;   2005, 2006, 2007 Free Software Foundation, Inc.
;; Author: Morten Welinder <terra@gnu.org>
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;             Headers come in three flavours called level 0, 1 and 2 headers.
;;             Level 2 header is free of DOS specific restrictions and most
;;             prevalently used.  Also level 1 and 2 headers consist of base
;;             and extension headers.  For more details see
;;             http://homepage1.nifty.com/dangan/en/Content/Program/Java/jLHA/Notes/Notes.html
;;             http://www.osirusoft.com/joejared/lzhformat.html
;; HOOKS: `foo' means one of the supported archive types.
  ;; make-temp-name is safe here because we use this name
  ;; to create a directory.
  "Directory for temporary files made by `arc-mode.el'."
  (if (and (not (executable-find "unzip"))
           (executable-find "pkunzip"))
      '("pkunzip" "-e" "-o-")
    '("unzip" "-qq" "-c"))
be added."
  (if (and (not (executable-find "zip"))
           (executable-find "pkzip"))
      '("pkzip" "-d")
    '("zip" "-d" "-q"))
  (if (and (not (executable-find "zip"))
           (executable-find "pkzip"))
      '("pkzip" "-u" "-P")
    '("zip" "-q"))
  (if (and (not (executable-find "zip"))
           (executable-find "pkzip"))
      '("pkzip" "-u" "-P")
    '("zip" "-q" "-k"))
(defvar archive-subtype nil "Symbol describing archive type.")
(defvar archive-file-list-start nil "Position of first contents line.")
(defvar archive-file-list-end nil "Position just after last contents line.")
(defvar archive-proper-file-start nil "Position of real archive's start.")
(defvar archive-read-only nil "Non-nil if the archive is read-only on disk.")
(defvar archive-local-name nil "Name of local copy of remote archive.")
(defvar archive-mode-map
  (let ((map (make-keymap)))
    (suppress-keymap map)
    (define-key map " " 'archive-next-line)
    (define-key map "a" 'archive-alternate-display)
    ;;(define-key map "c" 'archive-copy)
    (define-key map "d" 'archive-flag-deleted)
    (define-key map "\C-d" 'archive-flag-deleted)
    (define-key map "e" 'archive-extract)
    (define-key map "f" 'archive-extract)
    (define-key map "\C-m" 'archive-extract)
    (define-key map "g" 'revert-buffer)
    (define-key map "h" 'describe-mode)
    (define-key map "m" 'archive-mark)
    (define-key map "n" 'archive-next-line)
    (define-key map "\C-n" 'archive-next-line)
    (define-key map [down] 'archive-next-line)
    (define-key map "o" 'archive-extract-other-window)
    (define-key map "p" 'archive-previous-line)
    (define-key map "q" 'quit-window)
    (define-key map "\C-p" 'archive-previous-line)
    (define-key map [up] 'archive-previous-line)
    (define-key map "r" 'archive-rename-entry)
    (define-key map "u" 'archive-unflag)
    (define-key map "\M-\C-?" 'archive-unmark-all-files)
    (define-key map "v" 'archive-view)
    (define-key map "x" 'archive-expunge)
    (define-key map "\177" 'archive-unflag-backwards)
    (define-key map "E" 'archive-extract-other-window)
    (define-key map "M" 'archive-chmod-entry)
    (define-key map "G" 'archive-chgrp-entry)
    (define-key map "O" 'archive-chown-entry)

    (if (fboundp 'command-remapping)
        (progn
          (define-key map [remap advertised-undo] 'archive-undo)
          (define-key map [remap undo] 'archive-undo))
      (substitute-key-definition 'advertised-undo 'archive-undo map global-map)
      (substitute-key-definition 'undo 'archive-undo map global-map))

    (define-key map
      (if (featurep 'xemacs) 'button2 [mouse-2]) 'archive-extract)

    (if (featurep 'xemacs)
        ()				; out of luck

      (define-key map [menu-bar immediate]
        (cons "Immediate" (make-sparse-keymap "Immediate")))
      (define-key map [menu-bar immediate alternate]
        '(menu-item "Alternate Display" archive-alternate-display
          :enable (boundp (archive-name "alternate-display"))
          :help "Toggle alternate file info display"))
      (define-key map [menu-bar immediate view]
        '(menu-item "View This File" archive-view
          :help "Display file at cursor in View Mode"))
      (define-key map [menu-bar immediate display]
        '(menu-item "Display in Other Window" archive-display-other-window
          :help "Display file at cursor in another window"))
      (define-key map [menu-bar immediate find-file-other-window]
        '(menu-item "Find in Other Window" archive-extract-other-window
          :help "Edit file at cursor in another window"))
      (define-key map [menu-bar immediate find-file]
        '(menu-item "Find This File" archive-extract
          :help "Extract file at cursor and edit it"))

      (define-key map [menu-bar mark]
        (cons "Mark" (make-sparse-keymap "Mark")))
      (define-key map [menu-bar mark unmark-all]
        '(menu-item "Unmark All" archive-unmark-all-files
          :help "Unmark all marked files"))
      (define-key map [menu-bar mark deletion]
        '(menu-item "Flag" archive-flag-deleted
          :help "Flag file at cursor for deletion"))
      (define-key map [menu-bar mark unmark]
        '(menu-item "Unflag" archive-unflag
          :help "Unmark file at cursor"))
      (define-key map [menu-bar mark mark]
        '(menu-item "Mark" archive-mark
          :help "Mark file at cursor"))

      (define-key map [menu-bar operate]
        (cons "Operate" (make-sparse-keymap "Operate")))
      (define-key map [menu-bar operate chown]
        '(menu-item "Change Owner..." archive-chown-entry
          :enable (fboundp (archive-name "chown-entry"))
          :help "Change owner of marked files"))
      (define-key map [menu-bar operate chgrp]
        '(menu-item "Change Group..." archive-chgrp-entry
          :enable (fboundp (archive-name "chgrp-entry"))
          :help "Change group ownership of marked files"))
      (define-key map [menu-bar operate chmod]
        '(menu-item "Change Mode..." archive-chmod-entry
          :enable (fboundp (archive-name "chmod-entry"))
          :help "Change mode (permissions) of marked files"))
      (define-key map [menu-bar operate rename]
        '(menu-item "Rename to..." archive-rename-entry
          :enable (fboundp (archive-name "rename-entry"))
          :help "Rename marked files"))
      ;;(define-key map [menu-bar operate copy]
      ;;  '(menu-item "Copy to..." archive-copy))
      (define-key map [menu-bar operate expunge]
        '(menu-item "Expunge Marked Files" archive-expunge
          :help "Delete all flagged files from archive"))
      map))
  "Local keymap for archive mode listings.")
(defvar archive-file-name-indent nil "Column where file names start.")

(defvar archive-remote nil "Non-nil if the archive is outside file system.")
  "Non-nil when alternate information is shown.")
(defvar archive-superior-buffer nil "In archive members, points to archive.")
(defvar archive-subfile-mode nil "Non-nil in archive member buffers.")
(defun archive-l-e (str &optional len float)
  "Convert little endian string/vector STR to integer.
Alternatively, STR may be a buffer position in the current buffer
in which case a second argument, length LEN, should be supplied.
FLOAT, if non-nil, means generate and return a float instead of an integer
\(use this for numbers that can overflow the Emacs integer)."
            result (+ (if float (* result 256.0) (ash result 8))
		      (aref str (- len i)))))
  "Turn an integer like 0700 (i.e., 448) into a mode string like -rwx------."
  ;; FIXME: merge with tar-grind-file-mode.
  (string
    (if (zerop (logand  8192 mode))
	(if (zerop (logand 16384 mode)) ?- ?d)
      ?c) ; completeness
    (if (zerop (logand   256 mode)) ?- ?r)
    (if (zerop (logand   128 mode)) ?- ?w)
    (if (zerop (logand    64 mode))
	(if (zerop (logand  1024 mode)) ?- ?S)
      (if (zerop (logand  1024 mode)) ?x ?s))
    (if (zerop (logand    32 mode)) ?- ?r)
    (if (zerop (logand    16 mode)) ?- ?w)
    (if (zerop (logand     8 mode))
	(if (zerop (logand  2048 mode)) ?- ?S)
      (if (zerop (logand  2048 mode)) ?x ?s))
    (if (zerop (logand     4 mode)) ?- ?r)
    (if (zerop (logand     2 mode)) ?- ?w)
    (if (zerop (logand     1 mode)) ?- ?x)))
        (minute (logand (ash time -5) 63))
(defun archive-unixdate (low high)
  "Stringify Unix (LOW HIGH) date."
  (let ((str (current-time-string (cons high low))))
    (format "%s-%s-%s"
	    (substring str 8 10)
	    (substring str 4 7)
	    (substring str 20 24))))
(defun archive-unixtime (low high)
  "Stringify Unix (LOW HIGH) time."
  (let ((str (current-time-string (cons high low))))
    (substring str 11 19)))
Does not signal an error if optional argument NOERROR is non-nil."
	     (typename (capitalize (symbol-name type))))
	  (add-hook 'write-contents-functions 'archive-write-file nil t))
	(run-mode-hooks (archive-name "mode-hook") 'archive-mode-hook)

(let ((item1 '(archive-subfile-mode " Archive")))
      (setq minor-mode-alist (cons item1 minor-mode-alist))))
          ;; This pattern modelled on the BSD/GNU+Linux `file' command.
          ;; Have seen capital "LHA's", and file has lower case "LHa's" too.
          ;; Note this regexp is also in archive-exe-p.
          ((looking-at "MZ\\(.\\|\n\\)\\{34\\}LH[aA]'s SFX ") 'lzh-exe)
	  (t (error "Buffer format not recognized")))))
  (let ((inhibit-read-only t))
	(inhibit-read-only t))
    (restore-buffer-modified-p modified)
     (lambda (fil)
       ;; Using `concat' here copies the text also, so we can add
       ;; properties without problems.
       (let ((text (concat (aref fil 0) "\n")))
         (if (featurep 'xemacs)
             ()                         ; out of luck
           (add-text-properties
            (aref fil 1) (aref fil 2)
            '(mouse-face highlight
              help-echo "mouse-2: extract this file into a buffer")
            text))
         text))
To avoid very long lines archive mode does not show all information.
using `make-temp-file', and the generated name is returned."
	(make-temp-file
	  (if (if (fboundp 'msdos-long-file-names)
		  (not (msdos-long-file-names)))
	  ;; Maked sure all the leading directories in
	  ;; archive-local-name exist under archive-tmpdir, so that
	  ;; the directory structure recorded in the archive is
	  ;; reconstructed in the temporary directory.
	  (make-directory (file-name-directory archive-local-name) t)
	    (inhibit-read-only t))
    (let ((buffer-undo-list t)
	  (coding
	       ;; dos-w32.el defines the function
	       ;; find-buffer-file-type-coding-system for DOS/Windows
	       ;; systems which preserves the coding-system of existing files.
	       ;; (That function is called via file-coding-system-alist.)
	       ;; Here, we want it to act as if the extracted file existed.
	       ;; The following let-binding of file-name-handler-alist forces
	       ;; find-file-not-found-set-buffer-file-coding-system to ignore
	       ;; the file's name (see dos-w32.el).
		 (car (find-operation-coding-system
		       'insert-file-contents
		       (cons filename (current-buffer)) t))))))
      (after-insert-file-set-coding (- (point-max) (point-min))))))

(define-obsolete-function-alias 'archive-mouse-extract 'archive-extract "22.1")

(defun archive-extract (&optional other-window-p event)
  (interactive (list nil last-input-event))
  (if event (posn-set-point (event-end event)))
	 (arcfilename (expand-file-name (concat arcname ":" iname)))
      (if (and buffer
	       (string= (buffer-file-name buffer) arcfilename))
	(setq bufname (generate-new-buffer-name bufname))
        (with-current-buffer buffer
          (setq buffer-file-name arcfilename)
          (add-hook 'write-file-functions 'archive-write-file-member nil t)
	    (when (derived-mode-p 'archive-mode)
              (setq archive-remote t)
              (if read-only-p (setq archive-read-only t))
              ;; We will write out the archive ourselves if it is
              ;; part of another archive.
              (remove-hook 'write-contents-functions 'archive-write-file t))
            (run-hooks 'archive-extract-hooks)
          (cond
           (view-p (view-buffer buffer (and just-created 'kill-buffer)))
           ((eq other-window-p 'display) (display-buffer buffer))
           (other-window-p (switch-to-buffer-other-window buffer))
           (t (switch-to-buffer buffer))))))
			 (while (and bufs
                                     (not (with-current-buffer (car bufs)
                                            (derived-mode-p 'archive-mode))))
                           (setq bufs (cdr bufs)))
  (with-current-buffer arcbuf
  (let ((func (with-current-buffer arcbuf
                (archive-name "add-new-member")))
	(with-current-buffer arcbuf
      (let ((writer  (with-current-buffer archive-superior-buffer
                       (archive-name "write-file-member")))
	    (archive (with-current-buffer archive-superior-buffer
                       (archive-maybe-copy (buffer-file-name)))))
        (inhibit-read-only t))
    (restore-buffer-modified-p modified))
  (archive-flag-deleted p ?\s))
  (archive-flag-deleted (- p) ?\s))
	(inhibit-read-only t))
        (or (= (following-char) ?\s)
            (progn (delete-char 1) (insert ?\s)))
    (restore-buffer-modified-p modified)))
as a relative change like \"g+rw\" as for chmod(2)."
  "Change the name associated with this entry in the archive file."
	  (funcall func
  (let ((inhibit-read-only t))
	     ;; Convert to float to avoid overflow for very large files.
             (csize   (archive-l-e (+ p 15) 4 'float))
             (ucsize  (archive-l-e (+ p 25) 4 'float))
             (text    (format "  %8.0f  %-11s  %-8s  %s"
	      ;; p needs to stay an integer, since we use it in char-after
	      ;; above.  Passing through `round' limits the compressed size
	      ;; to most-positive-fixnum, but if the compressed size exceeds
	      ;; that, we cannot visit the archive anyway.
              p (+ p 29 (round csize)))))
	      (format "  %8.0f                         %d file%s"
(defun archive-arc-rename-entry (newname descr)
      (error "File names in arc files must not contain a directory component"))
	(inhibit-read-only t))
(defun archive-lzh-summarize (&optional start)
  (let ((p (or start 1)) ;; 1 for .lzh, something further on for .exe
    (while (progn (goto-char p)		;beginning of a base header.
      (let* ((hsize   (char-after p))	;size of the base header (level 0 and 1)
	     ;; Convert to float to avoid overflow for very large files.
	     (csize   (archive-l-e (+ p 7) 4 'float)) ;size of a compressed file to follow (level 0 and 2),
					;size of extended headers + the compressed file to follow (level 1).
             (ucsize  (archive-l-e (+ p 11) 4 'float))	;size of an uncompressed file.
	     (time1   (archive-l-e (+ p 15) 2))	;date/time (MSDOS format in level 0, 1 headers
	     (time2   (archive-l-e (+ p 17) 2))	;and UNIX format in level 2 header.)
	     (hdrlvl  (char-after (+ p 20))) ;header level
	     thsize		;total header size (base + extensions)
	     fnlen efnname osid fiddle ifnname width p2
	     neh	;beginning of next extension header (level 1 and 2)
	     mode modestr uid gid text dir prname
	     gname uname modtime moddate)
	(if (= hdrlvl 3) (error "can't handle lzh level 3 header type"))
	(when (or (= hdrlvl 0) (= hdrlvl 1))
	  (setq fnlen   (char-after (+ p 21))) ;filename length
	  (setq efnname (let ((str (buffer-substring (+ p 22) (+ p 22 fnlen))))	;filename from offset 22
	  (setq p2      (+ p 22 fnlen))) ;
	(if (= hdrlvl 1)
            (setq neh (+ p2 3))         ;specific to level 1 header
	  (if (= hdrlvl 2)
              (setq neh (+ p 24))))     ;specific to level 2 header
	(if neh		;if level 1 or 2 we expect extension headers to follow
	    (let* ((ehsize (archive-l-e neh 2))	;size of the extension header
		   (etype (char-after (+ neh 2)))) ;extension type
	      (while (not (= ehsize 0))
		 ((= etype 1)	;file name
		  (let ((i (+ neh 3)))
		    (while (< i (+ neh ehsize))
		      (setq efnname (concat efnname (char-to-string (char-after i))))
		      (setq i (1+ i)))))
		 ((= etype 2)	;directory name
		  (let ((i (+ neh 3)))
		    (while (< i (+ neh ehsize))
				    (setq dir (concat dir
		 ((= etype 80)		;Unix file permission
		  (setq mode (archive-l-e (+ neh 3) 2)))
		 ((= etype 81)		;UNIX file group/user ID
		  (progn (setq uid (archive-l-e (+ neh 3) 2))
			 (setq gid (archive-l-e (+ neh 5) 2))))
		 ((= etype 82)		;UNIX file group name
		  (let ((i (+ neh 3)))
		    (while (< i (+ neh ehsize))
		      (setq gname (concat gname (char-to-string (char-after i))))
		      (setq i (1+ i)))))
		 ((= etype 83)		;UNIX file user name
		  (let ((i (+ neh 3)))
		    (while (< i (+ neh ehsize))
		      (setq uname (concat uname (char-to-string (char-after i))))
		      (setq i (1+ i)))))
		(setq neh (+ neh ehsize))
		(setq ehsize (archive-l-e neh 2))
		(setq etype (char-after (+ neh 2))))
	      ;;get total header size for level 1 and 2 headers
	      (setq thsize (- neh p))))
	(if (= hdrlvl 0)  ;total header size
	    (setq thsize hsize))
        ;; OS ID field not present in level 0 header, use code 0 "generic"
        ;; in that case as per lha program header.c get_header()
	(setq osid (cond ((= hdrlvl 0)  0)
                         ((= hdrlvl 1)  (char-after (+ p 22 fnlen 2)))
                         ((= hdrlvl 2)  (char-after (+ p 23)))))
        ;; Filename fiddling must follow the lha program, otherwise the name
        ;; passed to "lha pq" etc won't match (which for an extract silently
        ;; results in no output).  As of version 1.14i it goes from the OS ID,
        ;; - For 'M' MSDOS: msdos_to_unix_filename() downcases always, and
        ;;   converts "\" to "/".
        ;; - For 0 generic: generic_to_unix_filename() downcases if there's
        ;;   no lower case already present, and converts "\" to "/".
        ;; - For 'm' MacOS: macos_to_unix_filename() changes "/" to ":" and
        ;;   ":" to "/"
	(setq fiddle (cond ((= ?M osid) t)
                           ((= 0 osid)  (string= efnname (upcase efnname)))))
	(setq ifnname (if fiddle (downcase efnname) efnname))
	(setq prname (if dir (concat dir ifnname) ifnname))
	(setq width (if prname (string-width prname) 0))
	(setq moddate (if (= hdrlvl 2)
			  (archive-unixdate time1 time2) ;level 2 header in UNIX format
			(archive-dosdate time2))) ;level 0 and 1 header in DOS format
	(setq modtime (if (= hdrlvl 2)
			  (archive-unixtime time1 time2)
			(archive-dostime time1)))
			  (format "  %8.0f  %5S  %5S  %s"
			(format "  %10s  %8.0f  %-11s  %-8s  %s"
				moddate
				modtime
				prname)))
				   (- (length text) (length prname))
                          files))
	(cond ((= hdrlvl 1)
	       ;; p needs to stay an integer, since we use it in goto-char
	       ;; above.  Passing through `round' limits the compressed size
	       ;; to most-positive-fixnum, but if the compressed size exceeds
	       ;; that, we cannot visit the archive anyway.
	       (setq p (+ p hsize 2 (round csize))))
	      ((or (= hdrlvl 2) (= hdrlvl 0))
	       (setq p (+ p thsize 2 (round csize)))))
	))
		       "  %8.0f                %d file%s"
		     "              %8.0f                         %d file%s")))
(defun archive-lzh-rename-entry (newname descr)
	     (inhibit-read-only t))
  (save-excursion
    (save-restriction
      (dolist (fil files)
	(let* ((p (+ archive-proper-file-start (aref fil 4)))
	       (inhibit-read-only t))
		     (aref fil 1) errtxt)))))))
   (lambda (old) (archive-calc-mode old newmode t))

;; -------------------------------------------------------------------------
;; Section: Lzh Self-Extracting .exe Archives
;;
;; No support for modifying these files.  It looks like the lha for unix
;; program (as of version 1.14i) can't create or retain the DOS exe part.
;; If you do an "lha a" on a .exe for instance it renames and writes to a
;; plain .lzh.

(defun archive-lzh-exe-summarize ()
  "Summarize the contents of an LZH self-extracting exe, for `archive-mode'."

  ;; Skip the initial executable code part and apply archive-lzh-summarize
  ;; to the archive part proper.  The "-lh5-" etc regexp here for the start
  ;; is the same as in archive-find-type.
  ;;
  ;; The lha program (version 1.14i) does this in skip_msdos_sfx1_code() by
  ;; a similar scan.  It looks for "..-l..-" plus for level 0 or 1 a test of
  ;; the header checksum, or level 2 a test of the "attribute" and size.
  ;;
  (re-search-forward "..-l[hz][0-9ds]-" nil)
  (archive-lzh-summarize (match-beginning 0)))

;; `archive-lzh-extract' runs "lha pq", and that works for .exe as well as
;; .lzh files
(defalias 'archive-lzh-exe-extract 'archive-lzh-extract
  "Extract a member from an LZH self-extracting exe, for `archive-mode'.")

  (let ((p (+ (point-min) (archive-l-e (+ (point) 16) 4)))
	     ;; (method  (archive-l-e (+ p 10) 2))
	     ;; Convert to float to avoid overflow for very large files.
             (ucsize  (archive-l-e (+ p 24) 4 'float))
             (text    (format "  %10s  %8.0f  %-11s  %-8s  %s"
	      (format "              %8.0f                         %d file%s"
  (if (equal (car archive-zip-extract) "pkzip")
      (dolist (fil files)
	(let* ((p (+ archive-proper-file-start (car (aref fil 4))))
	       (inhibit-read-only t))
        ))))
	     ;; Convert to float to avoid overflow for very large files.
             (ucsize  (archive-l-e (+ p 20) 4 'float))
             (text    (format "  %8.0f  %-11s  %-8s  %s"
        (setq maxlen (max maxlen width)
	      (format "  %8.0f                         %d file%s"
;; arch-tag: e5966a01-35ec-4f27-8095-a043a79b457b
;;; arc-mode.el ends here