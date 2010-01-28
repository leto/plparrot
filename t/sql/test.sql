\unset ECHO
\set QUIET 1
-- Turn off echo and keep things quiet.
-- Format the output for nice TAP.
\pset format unaligned
\pset tuples_only true
\pset pager
-- Revert all changes on failure.
\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true

-- Load the TAP functions.
BEGIN;
\i pgtap.sql
\i plparrot.sql

-- Plan the tests.
SELECT plan(5);

CREATE OR REPLACE FUNCTION create_plparrot()
RETURNS BOOLEAN
LANGUAGE SQL
AS $$
CREATE LANGUAGE plparrot;
SELECT true;
$$;
-- These functions should be written in PIR

CREATE FUNCTION test_void() RETURNS void AS $$ FAIL $$ LANGUAGE plparrot;

CREATE FUNCTION test_int() RETURNS int AS $$ select 1 as result $$ LANGUAGE plparrot;

CREATE FUNCTION test_int_int(int) RETURNS int AS $$ select $1 as result $$ LANGUAGE plparrot;

CREATE FUNCTION test_float() RETURNS float AS $$ select 1.0::float as result $$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar() RETURNS varchar(5) AS $$ select 'cheese' as result $$ LANGUAGE plparrot;

select is(test_void()::text,''::text,'We can return void');
select is(test_int(),1,'We can return an int');
select is(test_int_int(42),42,'We can return an int that was passed as an arg');
select is(test_float(), 1.0::float ,'We can return a float');
select is(test_varchar(), 'cheese', 'We can return a varchar');

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
