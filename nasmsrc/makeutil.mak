###############################################################################
#
#       MAKEFILE FOR:           PC-MOS utility programs
#
###############################################################################
#
# Default rules for this makefile.
#
more.com:       more.s version.inc
	nasm -f bin more.s -l more.lst -o more.com
