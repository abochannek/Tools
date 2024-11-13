;;; txtrpl-input.el --- Quail package for simple text replacement, similar to abbr-mode   -*-coding: utf-8;-*-

;; Keywords: mule, multilingual, input method

(require 'quail)

(quail-define-package
 "txtrpl-prefix" "Text Replacement Prefix" "TXT>" t
 "Text replacement input method with en_US layout and \\=`-key
 (backquote) prefix

  This is meant to address the limitation in abbr-mode that
  abbreviations cannot contain special characters.

   sequence | glyph | name
  ----------+-------+------------------------------
     \\=`\\=`     |   \\=`   | grave accent
     \\=`<-    |   ←   | left arrow
     \\=`->    |   →   | right arrow
     \\=`1/4   |   ¼   | one quarter
     \\=`1/2   |   ½   | one half
     \\=`3/4   |   ¾   | three quarters
     \\=`/u    |   µ   | micro sign
     \\=`^2    |   ²   | superscript two
     \\=`^3    |   ³   | superscript hree
     \\=`E=    |   €   | euro sign
" nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("``" ?\N{GRAVE ACCENT}) ; `
 ("`<-" ?\N{LEFTWARDS ARROW}) ; ←
 ("`->" ?\N{RIGHTWARDS ARROW}) ; →
 ("`1/4" ?\N{VULGAR FRACTION ONE QUARTER}) ; ¼
 ("`1/2" ?\N{VULGAR FRACTION ONE HALF}) ; ½
 ("`3/4" ?\N{VULGAR FRACTION THREE QUARTERS}) ; ¾
 ("`/u" ?\N{MICRO SIGN}) ; µ
 ("`^2" ?\N{SUPERSCRIPT TWO}) ; ²
 ("`^3" ?\N{SUPERSCRIPT THREE}) ; ³
 ("`E=" ?\N{EURO SIGN}) ; €
)
