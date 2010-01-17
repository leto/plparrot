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
INSERT INTO pg_catalog.pg_pltemplate(
    tmplname,
    tmpltrusted,
    tmpldbacreate,
    tmplhandler,
    tmpllibrary
)
VALUES (
    'plparrot',
    true,
    true,
    'plparrot_call_handler',
    '$libdir/plparrot'
);
CREATE LANGUAGE plparrot;

-- These functions should be written in PIR

CREATE FUNCTION test_void() RETURNS void AS $$ FAIL $$ LANGUAGE plparrot;

CREATE FUNCTION test_int() RETURNS int AS $$ select 1 as result $$ LANGUAGE plparrot;

CREATE FUNCTION test_int_int(int) RETURNS int AS $$ select $1 as result $$ LANGUAGE plparrot;

CREATE FUNCTION test_float() RETURNS float AS $$ select 1.0 as result $$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar() RETURNS varchar(5) AS $$ select 'cheese' as result $$ LANGUAGE plparrot;

select test_void();
select is(test_int(),1);
select is(test_int_int(42),42);

-- There does not seem to be any floating point comparison functions in pgTAP
--select like(test_float(), 1.0,1e-6);
select is(test_varchar(), 'cheese');

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
