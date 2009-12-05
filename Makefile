
all:
	cd src/handler; make

test:
	psql test <t/test.sql
