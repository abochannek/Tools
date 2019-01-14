ffnewtab
========

`ffnewtab` is an AppleScript to open a URL in Firefox on macOS. It is a slightly modified version of the one posted in this [Stack Overflow answer](https://stackoverflow.com/questions/48662733/mac-osx-firefox-new-tab-option-doesnt-work).

The only significant change is the loop that ensures Firefox is in the foreground. This has been tested on macOS 10.14 (Mojave) and Firefox Quantum.

This script works well with the Emacs `browse-url` function and Gnus external article browsing (`gnus-article-browse-html-article` or `K H`) with these custom variable settings:

```elisp
 '(browse-url-browser-function (quote browse-url-firefox))
 '(browse-url-firefox-program "firefox.sh")
```
