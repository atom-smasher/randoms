#!/bin/sh

## atom's "randoms" script
## v1.01, 18 Nov 2019, (c) atom(@)smasher.org
## v1.01f, 09 may 2022, (c) atom(@)smasher.org
## Distributed under the GNU General Public License
## http://www.gnu.org/copyleft/gpl.html
## originally posted - https://www.snbforums.com/threads/script-for-creating-random-numbers-and-more.60182/

## test for output format option
## thanks Dabombber for this section of code :)
case "$1" in
    '-f')
	## this gives hexadecimal output
	chars_match='0-9a-f'
	shift
	;;
    '-F')
	## this gives hexadecimal output, upper-case letters
	chars_match='0-9A-F'
	shift
	;;
    '-8')
	## this gives octal output
	chars_match='0-7'
	shift
	;;
    '-p')
	## random passwords
	chars_match='0-9a-zA-Z<>/\?!@#$%^&*()+=_,.-'
	## for random passwords, edit the character-set as desired
	## nb, '!-~' include all "normal" "printable" ASCII characters
	shift
	;;
    *)
	## default is decimal output
	chars_match='0-9'
	;;
esac

#### 1st argument
## $1 is number of digits output per line.
## 18 is a default, because that's what usually what expr can safely handle.
## this makes it easy to use this script for deriving random numbers within
##     a given range, eg for getting random numbers between 1-37, inclusive:
##     expr $( randoms ) % 37 + 1
digits_output=${1:-18}

#### 2nd argument
## $2 is number of output lines
## defaults to 1
lines_output=${2:-1}

## this displays on "-h", "--help", or any improper use
help () {
    echo "$(basename $0): usage:"
    echo "    $(basename $0) [-f|-F|-8|-p] [d [l]]"
    echo
    echo '    -f: hexadecimal output'
    echo '    -F: hexadecimal output, with upper-case letters'
    echo '    -8: octal output'
    echo '    -p: random passwords'
    echo '    d: number of digits (or characters) output per line'
    echo '    l: number of output lines'
    echo '    ** Default output is decimal format, 18 digits, 1 line'
    echo
    echo 'Examples:'
    echo '* Print 5 random decimal strings, each with 3 digits:'
    echo "    $(basename $0) 3 5"
    echo
    echo '* Print 1 random hexadecimal string with 32 digits:'
    echo "    $(basename $0) -f 32"
    echo
    echo '* Print 1 random decimal string with 300 digits:'
    echo "    $(basename $0) 300"
    echo
    echo '* Print 1 random password string with 12 characters:'
    echo "    $(basename $0) -p 12"
    echo
    echo "* Print 5 random MAC addresses:"
    echo "    $(basename $0) -F 12 5 | sed 's!.\{2\}!&:!g ; s!:\$!!' "
    echo
    echo "* Print a random (but probably invalid) UUID:"
    printf "    $(basename $0) -f 32 | sed -E 's/(.{8})(.{4})(.{4})(.{4})/\\\1-\\\2-\\\3-\\\4-/'\n"
    echo
    echo "* Print a (valid) random UUID (of a known or unknown variant; DCE, NCS, Microsoft, undefined):"
    printf "    $(basename $0) -f 31 | sed -E 's/(.{8})(.{4})(.{3})(.{4})/\\\1-\\\2-4\\\3-\\\4-/'\n"
    echo

    exit 1
}

## test that numeric arguments are sensible
## or print help (to stderr) and exit (exit status 1)
[ 0 -lt ${digits_output} ] 2> /dev/random || help 1>&2
[ 0 -lt ${lines_output}  ] 2> /dev/random || help 1>&2

n=1
## go through this loop once per line of output
while [ ${lines_output} -ge ${n} ]
do
    ## this gives output strings of arbitrary length
    tr -cd "${chars_match}" < /dev/urandom | head -c ${digits_output}
    echo
    n=$(( $n + 1 ))
done

exit 0

####################################
## NOTE THE "exit" DIRECTLY ABOVE ##
## WHAT'S BELOW HERE WILL NOT RUN ##
####################################

## for systems with wonky /dev/urandom, this (below) may be more robust.
## it's actually concerning how often "openssl enc -rc4" does better
##    than /dev/urandom, according to dieharder, although there are still
##    advantages to using /dev/urandom (such as portability and periodic reseeding)
## this is included here for reference and experimentation. have fun with it.
### rc4 is fast and does a good job passing the dieharder tests.
### "tail -c +17" strips out the "Salted__xxxxxxxx" string.
### "2> /dev/random" pipes openssl's errors into /dev/random; use /dev/null if needed.
### "head -c 16 /dev/urandom" derives a 128 bit password, read by "-pass stdin".
n=1
head -c 16 /dev/urandom | openssl enc -rc4 -pass stdin -in /dev/zero 2> /dev/random | tail -c +17 | while :
do
    ## go through this loop once per line of output
    ## this gives output strings of arbitrary length
    tr -cd "${chars_match}" | head -c ${digits_output}
    echo
    n=$(( $n + 1 ))
    [ ${lines_output} -ge ${n} ] || exit 0
done

##############################################
## and another alternative to /dev/urandom, ##
## this time using "haveged"                ##
##############################################
## stderr is directed from haveged into /dev/random,
##    if needed, direct that into /dev/null
n=1
## go through this loop once per line of output
haveged -n 0 2> /dev/random | while [ ${lines_output} -ge ${n} ]
do
    ## this gives output strings of arbitrary length
    tr -cd "${chars_match}" | head -c ${digits_output}
    echo
    n=$(( $n + 1 ))
done
