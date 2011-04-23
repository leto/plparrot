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
PARROTINC        = $(PARROTINCLUDEDIR)$(PARROTVERSIONDIR)
PARROTCONFIG     = $(PARROTLIBDIR)/$(PARROTVERSIONDIR)/parrot_config
PARROTLANGDIR	 = $(PARROTLIBDIR)$(PARROTVERSIONDIR)/languages
PERL6PBC		 = $(PARROTLANGDIR)/perl6/perl6.pbc
PARROTLDFLAGS    = $(shell parrot_config ldflags)
PARROTLINKFLAGS  = $(shell parrot_config inst_libparrot_linkflags) $(PARROTCONFIG)$O
PARROTSHA1       = $(shell parrot_config sha1)


PARROT_VERSION = $(shell parrot_config VERSION)

# We may need to do various things with various versions of PostgreSQL.
# VERSION     = $(shell $(PG_CONFIG) --version | awk '{print $$2}')
# PGVER_MAJOR = $(shell echo $(VERSION) | awk -F. '{ print ($$1 + 0) }')
# PGVER_MINOR = $(shell echo $(VERSION) | awk -F. '{ print ($$2 + 0) }')
# PGVER_PATCH = $(shell echo $(VERSION) | awk -F. '{ print ($$3 + 0) }')


override CPPFLAGS := -I$(PARROTINC) -I$(srcdir) $(CPPFLAGS)
override CFLAGS   := $(PARROTLDFLAGS) $(PARROTLINKFLAGS) $(CFLAGS)

ifneq ( $(strip $(wildcard $PERL6PBC)),)
override CFLAGS := $(CFLAGS) -DHAS_PERL6 -D'PERL6PBC="$(PERL6PBC)"'
endif

# It would be nice if this ran before we compiled
all: check_version headers
	@echo
	@echo
	@echo "Happy Hacking with PL/Parrot!"
	@echo
	@echo

headers:
	./bin/text2macro.pl plparrot_secure.pir > plparrot.h
	./bin/text2macro.pl plperl6.pir > plperl6.h

check_version:
	@echo
	@echo "Found Parrot Virtual Machine $(PARROT_VERSION) $(PARROTSHA1)"
	@echo

test: all
	psql -AX -f $(TESTS)

test_plperl6: all
	psql -AX -f $(PLPERL6_TESTS)

release:
	[ -d plparrot-$(VERSION) ] || ln -s . plparrot-$(VERSION)
	git ls-files | grep -v .gitignore | perl -lane 'print "plparrot-$(VERSION)/$$F[0]"' | tar -zcv -T - -f plparrot-$(VERSION).tar.gz
