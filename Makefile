NAME = plparrot
MODULE_big = src/plparrot
OBJS= src/plparrot.o
DATA_built = plparrot.sql
REGRESS_OPTS = --dbname=$(PL_TESTDB) --load-language=plpgsql
TESTS = $(wildcard t/sql/*.sql)
REGRESS = $(patsubst t/sql/%.sql,%,$(TESTS))

EXTRA_CLEAN = 

ifndef NO_PGXS
PGXS := $(shell pg_config --pgxs)
include $(PGXS)
else
subdir = contrib/plparrot
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

PARROTINCLUDEDIR = $(shell parrot_config includedir)
PARROTVERSION    = $(shell parrot_config versiondir)
PARROTINC        = "$(PARROTINCLUDEDIR)$(PARROTVERSION)"
PARROTLDFLAGS    = $(shell parrot_config ldflags)
PARROTLINKFLAGS  = $(shell parrot_config inst_libparrot_linkflags)

# We need to do various things with various versions of PostgreSQL.
# VERSION     = $(shell $(PG_CONFIG) --version | awk '{print $$2}')
# PGVER_MAJOR = $(shell echo $(VERSION) | awk -F. '{ print ($$1 + 0) }')
# PGVER_MINOR = $(shell echo $(VERSION) | awk -F. '{ print ($$2 + 0) }')
# PGVER_PATCH = $(shell echo $(VERSION) | awk -F. '{ print ($$3 + 0) }')

# this is not quite working yet
#PARROT_CCFLAGS=$(shell ~/svn/parrot/parrot_config ccflags)
#PARROT_CCFLAGS2=$(shell ~/svn/parrot/parrot_config ccflags_provisional)
override CPPFLAGS := -I$(PARROTINC) -I$(srcdir) $(CPPFLAGS)
override CFLAGS := $(PARROTLDFLAGS) $(PARROTLINKFLAGS) $(CFLAGS)

test: all
	psql -f $(TESTS)
