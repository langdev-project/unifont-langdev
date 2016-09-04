# This is the Unifont script for generating .ttf files from .hex.
# Notes and minor changes to the original made by Go Shoemake.

SHELL = /bin/sh

# Go Note : BINDIR is the directory containing the Unifont binaries.
# You'll need to compile your own from the Unifont source.

BINDIR = /usr/local/bin

# Go Note : I use the OS X application version of FontForge.
# If you use something else, you'll need to change that below.

FONTFORGE = /Applications/FontForge.app/Contents/MacOS/FontForge

#
# Default values, if not set on the command line when make is invoked:
#
# FONTFILE:  Prefix of the file name for input and output files.
# FONTNAME:  Name of the font inside a TTF file.
# PSNAME:    PostScript name of the font inside a TTF file; can't have spaces.
# COMBINING: Prefix of the file containing a list of combining characters.
#

FONTFILE=UnifontLANGDEV
FONTNAME=Unifont LANGDEV
PSNAME=UnifontLANGDEV
COMBINING=source/combining.txt

# Go Note: I've added 16HEX which is the folder of the 16px hex files,
# 32HEX which is the folder of the 32px hex files, and SPACES which is
# the spaces.hex file. FONTNAME32 and PSNAME32 give the names for the
# 32px version.

16HEX=source/hex
32HEX=source/hex-32
SPACES=source/spaces.hex
FONTNAME32=Unifont LANGDEV 32
PSNAME32=UnifontLANGDEV32

#
# The PostScript name of a font can't contain spaces--remove them.
# Could also use bash string replacement if you know you're using bash.
#

# Go Note: The Unifont LANGDEV TTF only contains LANGDEV glyphs, which
# were created by me. The full Unifont project has a much longer list
# of contributors.

COPYRIGHT = "Copyright (C) 2016 Margaret \"Go\" Shoemake. \
Licensed under the GNU General Public License; either version 2, or \
(at your option) a later version, with the GNU Font Embedding Exception."

# Go Note: The following version number is for 'LANGDEV in Unicode'.

UNICODE_VERSION = 2.1
PKG_REV = 01
VERSION = $(UNICODE_VERSION).$(PKG_REV)

#
# How to build unifont.ttf from GNU Unifont's unifont.hex
# -------------------------------------------------------
# Written by Luis Alejandro Gonzalez Miranda - http://www.lgm.cl/
#

#
# 2008 - Paul Hardy created this Makefile from Luis' original
# howto-build.sh and other bash scripts.  Those original scripts
# don't appear in this archive, but they can be retrieved from
# http://www.lgm.cl/.
#

# First of all, you need a Perl interpreter and FontForge.
#
# I don't remember all the steps, but I think it was as described by
# this script.

# This division is done only so the Simplify and RemoveOverlap
# operations don't use up too much memory, and because
# a .sfd generated from the whole unifont.hex would be too big to
# process all at once.

# Go Note: Right now 32px fonts aren't handled properly by hex2sfd :(

# all: 16 32
just16: 16

# Go Note: I've added a few lines to move the font and combining
# files out into the open if they aren't already.

$(FONTFILE).hex: $(SPACES) $(16HEX)/*
	cat $(SPACES) $(16HEX)/* > $(FONTFILE).hex

$(FONTFILE)-combining.txt: $(COMBINING)
		cp -f $(COMBINING) $(FONTFILE)-combining.txt

$(FONTFILE)-32.hex: $(SPACES) $(32HEX)/*
	cat $(SPACES) $(32HEX)/* > $(FONTFILE)-32.hex

$(FONTFILE)-32-combining.txt: $(COMBINING)
		cp -f $(COMBINING) $(FONTFILE)-32-combining.txt

#
# Commented out this operation on SFD file because not all applications
# correctly interpreted the settings:
#
#	    SetFontNames("UnifontMedium", "GNU", "Unifont", "Medium", $(COPYRIGHT), "$(VERSION)"); \
#
# Convert unifont.hex to unifont.sfd as a single file, then generate
# an outline TrueType font.
#

# Go Note: I slightly simplified this to do everything in one step.

16: $(FONTFILE).hex $(BINDIR)/hex2sfd $(FONTFILE)-combining.txt
	$(BINDIR)/hex2sfd $(FONTFILE)-combining.txt < $(FONTFILE).hex > $(FONTFILE).sfd
	$(FONTFORGE) -lang=ff -c \
	   'Open($$1); \
	    SetFontNames("$(PSNAME)", \
		"$(FONTNAME)", "$(FONTNAME)", "Medium", \
		$(COPYRIGHT), "$(VERSION)"); \
	    SelectAll(); \
	    RemoveOverlap(); \
	    Simplify(64,1); \
	    Save($$1); \
		Generate($$2);' \
	   $(FONTFILE).sfd $(PSNAME).ttf
	rm -f $(FONTFILE).hex $(FONTFILE)-combining.txt

# Go Note: …And the 32px version:

32: $(FONTFILE)-32.hex $(BINDIR)/hex2sfd $(FONTFILE)-32-combining.txt
	$(BINDIR)/hex2sfd $(FONTFILE)-32-combining.txt < $(FONTFILE)-32.hex > $(FONTFILE)-32.sfd
	$(FONTFORGE) -lang=ff -c \
	   'Open($$1); \
	    SetFontNames("$(PSNAME32)", \
		"$(FONTNAME32)", "$(FONTNAME32)", "Medium", \
		$(COPYRIGHT), "$(VERSION)"); \
	    SelectAll(); \
	    RemoveOverlap(); \
	    Simplify(64,1); \
	    Save($$1); \
		Generate($$2);' \
	   $(FONTFILE)-32.sfd $(PSNAME32).ttf
	rm -f $(FONTFILE)-32.hex $(FONTFILE)-32-combining.txt

#
# This fontforge script reads a BDF font file and generates an SBIT font file.
# Author: written by Qianqian Fang, given to Paul Hardy in 2008.
# The SBIT font is far smaller than the default outline TrueType font
# and takes far less time to build than the outline font.  However, it
# isn't scalable.  An SBIT font could be created and merged with the
# larger TTF font using fontforge, but I (Paul Hardy) haven't noticed
# any degradation in the screen rendering of just the outline TTF font
# that this Makefile produces as its final product.  This is with
# daily use of this Makefile's default TrueType font.
#
# This builds an SBIT font from the unifont_sample BDF font.  The
# BDF font already contains font name, etc., so they don't need to
# be set using SetFontNames; those parameters are left null so the
# existing font's values will be preserved.  However, Fontforge
# does not read the FONT_VERSION property so Paul Hardy added the
# the SetFontNames call.
#
# Commented out because not all applications correctly interpreted
# the settings:
#
#	    SetFontNames("","","","","","$(VERSION)"); \

sbit: $(FONTFILE).bdf
	$(FONTFORGE) -lang=ff -c \
	   'New(); \
	    Import($$1); \
	    SetFontNames("","","","","","$(VERSION)"); \
	    Generate($$2, "ttf"); \
	    Close()' \
	   $(FONTFILE).bdf $(FONTFILE).ttf
	\rm -f $(FONTFILE).bdf

#
# Delete files copied into this directory to build TTF fonts.
#
clean:
	\rm -f *.bdf *.hex *.txt

#
# Delete files created within this directory while building TTF fonts.
#
distclean: clean
	\rm -f *.sfd *.ttf

.PHONY: all 16 32 sbit clean distclean
