(load "../util/file.lisp")
(load "../util/arrows.lisp")
(load "../util/string.lisp")
(load "../util/template.lisp")
(load "../util/queue.lisp")

(defun get-input (filename)
  (->> filename
       (read-lines)
       (car)
       (split-str ",")
       (mapcar 'parse-integer)))

(defun get-num (array index)
  (aref array (aref array index)))

(defvar *positional* 0)
(defvar *immediate* 1)
(defvar *relative* 2)

(defvar *par1* 1)
(defvar *par2* 2)
(defvar *par3* 3)

(defvar *halt* 0)
(defvar *exit* 1)

(defclass intcode-computer ()
  ((memory
     :initform (make-hash-table)
     :accessor memory)
   (index
     :initform 0
     :accessor index)
   (input
     :initform nil
     :initarg :in
     :accessor in)
   (output
     :initform '()
     :accessor output)
   (rel-base
     :initform 0
     :accessor rel-base)
   (instructons
     :initarg :instructions
     :accessor instructions)))

(defun consume-in (comp)
  (let ((val (car (in comp))))
    (setf (in comp) (cdr (in comp)))
    val))

(defun mem-write (comp addr val)
  (if (>= addr (length (instructions comp)))
    (setf (gethash addr (memory comp)) val)
    (setf (aref (instructions comp) addr) val)))

(defun mem-read (comp addr)
  (if (>= addr (length (instructions comp)))
    (gethash addr (memory comp) 0)
    (aref (instructions comp) addr)))

(defun op (comp)
  (aref (instructions comp) (index comp)))

(defun get-index (comp &key (offset 0) (rel-base 0))
  (+ rel-base (aref (instructions comp) (+ (index comp) offset))))

(defun mode-off (comp off)
  (digit (op comp) (+ 1 off)))

(defun mem-write-addr (comp off)
  (let ((mode (digit (op comp) (1+ off))))
    (cond
      ((= mode *positional*)
       (get-index comp :offset off))
      ((= mode *relative*)
       (get-index comp :rel-base (rel-base comp) :offset off)))))

(defun op-code (comp)
  (+ (* 10 (digit (op comp) 1)) (digit (op comp) 0)))

(defun get-param (comp off)
  (let ((mode (digit (op comp) (1+ off))))
    (cond
      ((= mode *positional*)
       (mem-read comp (get-index comp :offset off)))
      ((= mode *immediate*)
       (mem-read comp (+ (index comp) off)))
      ((= mode *relative*)
       (mem-read comp (get-index comp :rel-base (rel-base comp) :offset off))))))

(defun handle (comp op &optional flag)
  (let* ((fst (get-param comp *par1*))
         (snd (get-param comp *par2*))
         (res (funcall op fst snd))
         (res-addr (mem-write-addr comp *par3*)))
    (if flag
      (mem-write comp res-addr (if res 1 0))
      (mem-write comp res-addr res))

    (run-with-inc comp 4)))

(defun inc-index (comp inc)
  (setf (index comp) (+ (index comp) inc)))

(defun run-with-inc (comp inc)
  (inc-index comp inc)
  (run comp))

(defun run-with-set (comp val)
  (setf (index comp) val)
  (run comp))

(defun run (comp)
  (let ((op (op-code comp)))
    (cond
      ((= op 99)
       (list 1 -1))
      ((= op 1)
       (handle comp '+))
      ((= op 2)
       (handle comp '*))
      ((= op 3)
       (mem-write comp (mem-write-addr comp *par1*) (consume-in comp))
       (run-with-inc comp 2))
      ((= op 4)
       (let ((out (get-param comp *par1*)))
         (inc-index comp 2)
         (setf (output comp) (cons out (output comp)))
         (list 0 comp out)))
      ((= op 5)
       (if (not (eql (get-param comp *par1*) 0))
         (run-with-set comp (get-param comp *par2*))
         (run-with-inc comp 3)))
      ((= op 6)
       (if (eql (get-param comp *par1*) 0)
         (run-with-set comp (get-param comp *par2*))
         (run-with-inc comp 3)))
      ((= op 7)
       (handle comp '< t))
      ((= op 8)
       (handle comp '= t))
      ((= op 9)
       (setf (rel-base comp) (+ (rel-base comp) (get-param comp *par1*)))
       (run-with-inc comp 2)))))

(defun digit (a b)
  (mod (floor a (expt 10 b)) 10))

(defun get-array (input)
  (make-array (length input) :initial-contents input))

(defun key-val (ht)
  (loop for k being the hash-keys in ht using (hash-value v)
        collect (list k v)))

(defparameter *scaffolding* 35)
(defparameter *open-space* 46)
(defparameter *newline* 10)

(defun create-scaffolding (input)
  (let ((comp (make-instance 'intcode-computer :instructions (get-array input)))
        (map (make-hash-table :test 'equal))
        (x 0)
        (y 0))
    (labels ((helper ()
                     (let ((out (run comp)))
                       (if (= (car out) *exit*)
                         map
                         (let ((sym (third out)))
                           (cond
                             ((= sym *newline*)
                              (incf y 1)
                              (setf x 0))
                             (t
                               (setf (gethash (list x y) map) sym)
                               (incf x 1)))
                           (helper))))))
      (helper))))

(defun neighbors (point)
  (list
    (list (1+ (car point)) (cadr point))
    (list (1- (car point)) (cadr point))
    (list (car point) (1+ (cadr point)))
    (list (car point) (1- (cadr point)))))

(defun is-intersection (map point)
  (when (= (gethash point map) *scaffolding*)
    (let ((sum 0))
      (loop for dir in (neighbors point) do
            (when (and 
                    (gethash dir map)
                    (= (gethash dir map) *scaffolding*))
              (incf sum 1)))
      (= sum 4))))

(defun intersections (map)
  (let ((lst '()))
    (loop for kv in (key-val map) do
          (when (is-intersection map (car kv))
            (setf lst (cons (car kv) lst))))
    lst))

(defun sum (intersections)
  (reduce '+ 
          intersections
          :key (lambda (x) (reduce '* x))))

(defun string-to-chars (s)
  (mapcar 'char-int (coerce s 'list)))

(defun part-one (input)
  (->> input
       (create-scaffolding)
       (intersections)
       (sum)))

;; NOTE: I solved the maze by hand. Running this progam with 
;; with any other input will most likely fail.
;; I recommend solving your input by hand as well, and
;; substituting the routes with your solution.
(defun part-two (input)
  (setf (car input) 2)
  (let* ((main (format nil "A,B,A,B,C,B,A,C,B,C~C" #\newline))
         (A (format nil "L,12,L,8,R,10,R,10~C" #\newline))
         (B (format nil "L,6,L,4,L,12~C" #\newline))
         (C (format nil "R,10,L,8,L,4,R,10~C" #\newline))
         (cont (format nil "n~C" #\newline))
         (computer-input (string-to-chars (concatenate 'string main A B C cont)))
         (comp (make-instance 'intcode-computer 
                              :instructions (get-array input)
                              :in computer-input)))
    (labels ((run-intcode-program ()
                                  (let ((res (run comp)))
                                    (if (= (car res) *exit*)
                                      res
                                      (run-intcode-program)))))
      (run-intcode-program)
      (car (output comp)))))

(defun main()
  (let ((input (get-input (input))))
    (my-timer 'Silver #'part-one input)
    (my-timer 'Gold #'part-two input)))
