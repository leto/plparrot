# pllolcode Makefile $Id: Makefile,v 1.9 2009/05/04 15:04:55 eggyknap Exp $

MODULE_big = plparrot
OBJS= plparrot.o

EXTRA_CLEAN = 

ifndef DONT_USE_PGXS
PGXS := $(shell pg_config --pgxs)
include $(PGXS)
else
subdir = contrib/plparrot
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif


