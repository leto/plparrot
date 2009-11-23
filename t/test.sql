\set ECHO
\set QUIET 1
-- Turn off echo and keep things quiet.
-- Format the output for nice TAP.
\pset format unaligned
\pset tuples_only true
\pset pager
-- Revert all changes on failure.
\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true
\set QUIET 1
-- Load the TAP functions.
BEGIN;
    \i pgtap.sql
-- Plan the tests.
SELECT plan(2);

--DROP FUNCTION plparrot_call_handler() CASCADE;
-- TODO: Make this configurable
CREATE FUNCTION plparrot_call_handler() RETURNS LANGUAGE_HANDLER AS '/Users/leto/git/postgresql/contrib/plparrot/libplparrot.so' LANGUAGE C;
CREATE LANGUAGE plparrot HANDLER plparrot_call_handler;

CREATE FUNCTION test_void() RETURNS void AS $$ FAIL $$ LANGUAGE plparrot;

CREATE FUNCTION test_int() RETURNS int AS $$ 1 $$ LANGUAGE plparrot;

CREATE FUNCTION test_int_int(int) RETURNS int AS $$ $1 $$ LANGUAGE plparrot;

CREATE FUNCTION test_float() RETURNS float AS $$ 1.0 $$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar() RETURNS varchar(5) AS $$ 'cheese' $$ LANGUAGE plparrot;

select test_void();
select is(test_int(),1);
select is(test_int_int(42),42);
-- these give a bus error on darwin/x86 + Postgres 8.3.8
--select test_float();
--select test_varchar();

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
