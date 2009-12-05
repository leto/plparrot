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

# this doesn't work correctly
#override CPPFLAGS :=-I/usr/local/include/parrot/1.8.0 -I$(includedir_server) -I$(includedir_internal) $(CPPFLAGS)

# We need to do various things with various versions of PostgreSQL.
VERSION     = $(shell $(PG_CONFIG) --version | awk '{print $$2}')
PGVER_MAJOR = $(shell echo $(VERSION) | awk -F. '{ print ($$1 + 0) }')
PGVER_MINOR = $(shell echo $(VERSION) | awk -F. '{ print ($$2 + 0) }')
PGVER_PATCH = $(shell echo $(VERSION) | awk -F. '{ print ($$3 + 0) }')
