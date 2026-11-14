###############################################################################
#
#       MAKEFILE FOR:           PC-MOS utility programs
#
###############################################################################
#
# Default rules for this makefile.
#
all:		more.com filter.com netname.com

more.com:       more.s version.inc
	nasm -f bin more.s -l more.lst -o more.com

filter.com:	filter.s version.inc
	nasm -f bin filter.s -l filter.lst -o filter.com

netname.com:	netname.s version.inc
	nasm -f bin netname.s -l netname.lst -o netname.com
