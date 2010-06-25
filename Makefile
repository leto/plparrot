NAME = plparrot
MODULE_big = plparrot
OBJS= plparrot.o
DATA_built = plparrot.sql
REGRESS_OPTS = --dbname=$(PL_TESTDB) --load-language=plpgsql
TESTS = t/sql/test.sql
PLPERL6_TESTS = t/sql/plperl6.sql
REGRESS = $(patsubst t/sql/%.sql,%,$(TESTS))

EXTRA_CLEAN =

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

O 				 = $(shell parrot_config o)
PARROTINCLUDEDIR = $(shell parrot_config includedir)
PARROTVERSIONDIR = $(shell parrot_config versiondir)
PARROTLIBDIR     = $(shell parrot_config libdir)
PARROTINC        = "$(PARROTINCLUDEDIR)$(PARROTVERSIONDIR)"
PARROTCONFIG     = $(PARROTLIBDIR)/$(PARROTVERSIONDIR)/parrot_config
PARROTLDFLAGS    = $(shell parrot_config ldflags)
PARROTLINKFLAGS  = $(shell parrot_config inst_libparrot_linkflags) $(PARROTCONFIG)$O
PARROTREVISION   = $(shell parrot_config revision)
MINPARROTREVISION= 45961

# This will only work on unixy boxens
# Which OS's does PL/Parrot want to support?

PARROT_IS_INSECURE = $(shell expr $(PARROTREVISION) \< $(MINPARROTREVISION))

# We may need to do various things with various versions of PostgreSQL.
# VERSION     = $(shell $(PG_CONFIG) --version | awk '{print $$2}')
# PGVER_MAJOR = $(shell echo $(VERSION) | awk -F. '{ print ($$1 + 0) }')
# PGVER_MINOR = $(shell echo $(VERSION) | awk -F. '{ print ($$2 + 0) }')
# PGVER_PATCH = $(shell echo $(VERSION) | awk -F. '{ print ($$3 + 0) }')

override CPPFLAGS := -I$(PARROTINC) -I$(srcdir) $(CPPFLAGS)
override CFLAGS   := $(PARROTLDFLAGS) $(PARROTLINKFLAGS) $(CFLAGS)

ifdef ($(PERL6PBC))
override CFLAGS := $(CFLAGS) -DHAS_PERL6 -D'PERL6PBC="$(PERL6PBC)"'
endif

# It would be nice if this ran before we compiled
all: check_revision headers
	@echo "\n\n\tHappy Hacking with PL/Parrot!\n\n"

headers:
	./bin/text2macro.pl plparrot_secure.pir > plparrot.h
	./bin/text2macro.pl plperl6.pir > plperl6.h

check_revision:
ifeq ($(PARROT_IS_INSECURE),1)
	@echo "***************** SECURITY WARNING ************"
	@echo "This version of Parrot (r$(PARROTREVISION)) does not support the security features that PL/Parrot needs to prevent filesystem access"
	@echo "***********************************************"
else
	@echo "Found a sufficiently new version of Parrot r$(PARROTREVISION)"
endif

test: all
	psql -AX -f $(TESTS)

test_plperl6: all
	psql -AX -f $(PLPERL6_TESTS)
