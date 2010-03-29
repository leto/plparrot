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

CREATE FUNCTION test_void() RETURNS void AS $$
.sub foo_void
    .return()
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_int() RETURNS int AS $$
.sub foo_int
    .return(1)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_int_int(int) RETURNS int AS $$
.sub foo_int_int
    .param int x
    .return(x)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_float() RETURNS float AS $$
.sub foo_float
    .return(1.0)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar(text) RETURNS varchar(5) AS $$
.sub foo_varchar
    .param string s
    .return(s)
.end
$$ LANGUAGE plparrot;

select is(test_varchar('cheese'::text), 'cheese', 'We can return a varchar');
select is(test_int(),1,'We can return an int');
select is(test_void()::text,''::text,'We can return void');
select is(test_float(), 1.0::float ,'We can return a float');
select is(test_int_int(42),42,'We can return an int that was passed as an arg');

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
