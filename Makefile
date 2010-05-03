NAME = plparrot
MODULE_big = plparrot
OBJS= plparrot.o
DATA_built = plparrot.sql
REGRESS_OPTS = --dbname=$(PL_TESTDB) --load-language=plpgsql
TESTS = $(wildcard t/sql/*.sql)
REGRESS = $(patsubst t/sql/%.sql,%,$(TESTS))

EXTRA_CLEAN = 

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

PARROTINCLUDEDIR = $(shell parrot_config includedir)
PARROTVERSIONDIR = $(shell parrot_config versiondir)
PARROTINC        = "$(PARROTINCLUDEDIR)$(PARROTVERSIONDIR)"
PARROTLDFLAGS    = $(shell parrot_config ldflags)
PARROTLINKFLAGS  = $(shell parrot_config inst_libparrot_linkflags)
PARROTLIBDIR     = $(shell parrot_config libdir)
PARROTP6OBJECT   = $(PARROTLIBDIR)$(PARROTVERSIONDIR)/library/P6object.pbc
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
override CFLAGS := $(PARROTLDFLAGS) $(PARROTLINKFLAGS) $(CFLAGS) -D'PARROTP6OBJECT="$(PARROTP6OBJECT)"'

# It would be nice if this ran before we compiled
all: check_revision

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
