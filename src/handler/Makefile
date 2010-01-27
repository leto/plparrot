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

PARROTINC = $(shell parrot_config includedir)
# We need to do various things with various versions of PostgreSQL.
VERSION     = $(shell $(PG_CONFIG) --version | awk '{print $$2}')
PGVER_MAJOR = $(shell echo $(VERSION) | awk -F. '{ print ($$1 + 0) }')
PGVER_MINOR = $(shell echo $(VERSION) | awk -F. '{ print ($$2 + 0) }')
PGVER_PATCH = $(shell echo $(VERSION) | awk -F. '{ print ($$3 + 0) }')

# this is not quite working yet
#PARROT_CCFLAGS=$(shell ~/svn/parrot/parrot_config ccflags)
#PARROT_CCFLAGS2=$(shell ~/svn/parrot/parrot_config ccflags_provisional)
override CPPFLAGS :=-I$(PARROTINC) -I$(srcdir) $(CPPFLAGS)
