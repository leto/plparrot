
all:
	cd src/handler; make

test: all
	psql test --no-psqlrc --no-align --quiet --pset pager= --pset tuples_only=true \
	--set ON_ERROR_ROLLBACK=1 --set ON_ERROR_STOP=1 -f t/test.sql

clean:
	cd src/handler; make clean

redo: clean all

redotest: clean test

install: all
	cd src/handler; make install
