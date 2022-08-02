# randoms
Generate random numbers 

This is one of those scripts I should have written a long time ago.

Here's the output from running the script with the `-h` option:
```
randoms: usage:
    randoms [-f|-F|-8|-p] [d [l]]

    -f: hexadecimal output
    -F: hexadecimal output, with upper-case letters
    -8: octal output
    -p: random passwords
    d: number of digits (or characters) output per line
    l: number of output lines
    ** Default output is decimal format, 18 digits, 1 line

Examples:
* Print 5 random decimal strings, each with 3 digits:
    randoms 3 5

* Print 1 random hexadecimal string with 32 digits:
    randoms -f 32

* Print 1 random decimal string with 300 digits:
    randoms 300

* Print 1 random password string with 12 characters:
    randoms -p 12

* Print 5 random MAC addresses:
    randoms -F 12 5 | sed 's!.\{2\}!&:!g ; s!:$!!' 

* Print a random (but probably invalid) UUID:
    randoms -f 32 | sed -E 's/(.{8})(.{4})(.{4})(.{4})/\1-\2-\3-\4-/'

* Print a (valid) random UUID (of a known or unknown variant; DCE, NCS, Microsoft, undefined):
    randoms -f 31 | sed -E 's/(.{8})(.{4})(.{3})(.{4})/\1-\2-4\3-\4-/'
```
