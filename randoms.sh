#!/bin/sh

## atom's "randoms" script
## v1.01, 18 Nov 2019, (c) atom(@)smasher.org
## v1.2d, 23 Dec 2023, (c) atom(@)smasher.org
## https://github.com/atom-smasher/randoms
## Distributed under the GNU General Public License
## http://www.gnu.org/copyleft/gpl.html
## originally posted - https://www.snbforums.com/threads/script-for-creating-random-numbers-and-more.60182/

## this displays on "-h", "--help", or any improper use
help () {
    echo "$(basename $0): usage:"
    echo "  $(basename $0) [-f|-F|-x|-X|-8|-o|-d|-p] [DIGITS [LINES]]"
    echo '    -f:     hexadecimal output'
    echo '    -F:     hexadecimal output, with upper-case letters'
    echo '    -x:     like "-f", but with "0x" prefixes'
    echo '    -X:     like "-F", but with "0x" prefixes'
    echo '    -8:     octal output'
    echo '    -o:     like "-8", but with "0" prefixes'
    echo '    -d:     decimal output, with no leading zeros'
    echo '    -p:     random passwords'
    echo '    DIGITS: number of digits (or characters) output per line'
    echo '    LINES:  number of output lines, or "-" for unlimited'
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

    exit ${1}
}

## set the default here
prefix_lines=n

## test for output format option
## thanks Dabombber for this section of code :)
## this script does *not* use getopts, because it was originally written for ASUSWRT-Merlin, which does not support getopts in busybox sh
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
    '-x')
	## this gives hexadecimal output, 0x prefix
	chars_match='0-9a-f'
	prefix_lines=x
	shift
	;;
    '-X')
	## this gives hexadecimal output, upper-case letters, 0x prefix
	chars_match='0-9A-F'
	prefix_lines=x
	shift
	;;
    '-8')
	## this gives octal output
	chars_match='0-7'
	shift
	;;
    '-o')
	## this gives octal output, with "0" prefix
	chars_match='0-7'
	prefix_lines=o
	shift
	;;	
    '-p')
	## random passwords
	chars_match='0-9a-zA-Z<>/\?!@#$%^&*()+=_,.-'
	## for random passwords, edit the character-set as desired
	## nb, '!-~' include all "normal" "printable" ASCII characters
	shift
	;;
    -d)
	## decimal output, strip leading zeros
	chars_match='0-9'
	prefix_lines=d
	shift
	;;
    -h|--help)
	## help
	help 0
	;;
    *)
	## default is decimal output
	chars_match='0-9'
	;;
esac

#### 1st argument
## $1 is number of digits output per line.
## 18 is a default, because that's what `expr` can typically handle safely;
##    bear in mind this was originally written for the ASUSWRT-Merlin.
## this makes it easy to use this script for deriving random numbers within
##     a given range, eg for getting random numbers between 0-36, inclusive:
##     expr $( randoms ) % 37
## nb, that example has no modulo bias: 27027027027027027 * 37 = 999999999999999999
digits_output=${1:-18}

#### 2nd argument
## $2 is number of output lines
## defaults to 1
lines_output=${2:-1}

## test that numeric arguments are sensible
## or print help (to stderr) and exit (exit status 1)
[ 0 -lt ${digits_output} ] 2> /dev/random || help 1 1>&2
[ 0 -lt ${lines_output}  ] 2> /dev/random || [ '-' = ${lines_output} ] || help 2 1>&2

engine_urandom () {
    ## the "normal" random engine. should work well on most systems
    ## if needed/desired, one of the other "engines" can be used,
    ##    which requires a little bit of editing
    tr -cd "${1}" < /dev/urandom
}

engine_openssl_rc4 () {
    ## for systems with wonky /dev/urandom, this (below) may be more robust.
    ## it's actually concerning how often "openssl enc -rc4" does better
    ##    than /dev/urandom, according to dieharder, although there are still
    ##    advantages to using /dev/urandom (such as portability and periodic reseeding)
    ## this is included here for reference and experimentation. have fun with it.
    ## rc4 is fast and does a good job passing the dieharder tests.
    ## "tail -c +17" strips out the "Salted__xxxxxxxx" string; so does "-nosalt", which is more efficient
    ## "2> /dev/random" pipes openssl's errors into /dev/random; use /dev/null if needed.
    ## "head -c 16 /dev/urandom" derives a 128 bit binary password, read by "-pass stdin".
    ##
    ## or, for example, use a 192 bit binary password for aes-192-ctr:
    ##     head -c 24 /dev/urandom | openssl enc -aes-192-ctr -iter 1 -nosalt -pass stdin -in /dev/zero
    head -c 16 /dev/urandom | openssl enc -rc4 -provider legacy -provider default -iter 1 -nosalt -pass stdin -in /dev/zero 2> /dev/null | tr -cd "${1}"
    ##
    ## older versions of openssl will need the line below uncommented
    #head -c 16 /dev/urandom | openssl enc -rc4 -iter 1 -nosalt -pass stdin -in /dev/zero 2> /dev/null | tr -cd "${1}"

}

engine_haveged () {
    ## and another alternative to /dev/urandom, this time using "haveged"
    ## haveged can take a few moments to initialise, using the default "--onlinetest'
    haveged -n 0 2> /dev/null | tr -cd "${1}"
}

print_lines () {
    ## prefix lines, or trim leading zeros, as needed
    case "${3}" in
	n)
	    ## no prefix
	    engine_urandom "${1}" | fold -w ${2}
	    ;;
	x)
	    ## "0x" prefix
	    engine_urandom "${1}" | fold -w ${2} | sed 's!^!0x!'
	    ;;
	o)
	    ## "0" prefix
	    engine_urandom "${1}" | fold -w ${2} | sed 's!^!0!'
	    ;;
	d)
	    ## strip leading zeros
	    engine_urandom "${1}" | fold -w ${2} | sed 's!^00*!!'
	    ;;
    esac
    ## nb, this paste/yes trick is a very slightly faster way to add prefixes to long lists,
    ##    but it requires process substitution, which is not supported in sh
    ## just sharing it here as a teachable example:
    ##    randoms -f 6 - | paste -d '' <( yes 0x ) - | head -n 10
}

## print output
if [ '-' = ${lines_output} ]
then
    ## if "LINES" is "-", keep spitting out data until killed
    print_lines "${chars_match}" "${digits_output}" "${prefix_lines}"
else
    ## print "LINES" lines, then stop
    #engine_urandom "${chars_match}" | fold -w ${digits_output} | head -n ${lines_output}
    print_lines "${chars_match}" "${digits_output}" "${prefix_lines}" | head -n ${lines_output}
fi

exit 0
