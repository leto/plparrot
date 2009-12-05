
all:
	cd src/handler; make

test: all
	psql test <t/test.sql

clean:
	cd src/handler; make clean

redo: clean all

redotest: clean test
