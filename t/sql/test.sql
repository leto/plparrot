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
SELECT plan(11);

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

CREATE FUNCTION test_int_in(int) RETURNS int AS $$
.sub foo_int_int
    .param int x
    .return(1)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_int_out(int) RETURNS int AS $$
.sub foo_int_int
    .param int x
    .return(42)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_increment_int_int(int) RETURNS int AS $$
.sub foo_int_int
    .param int x
    inc x
    .return(x)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_float() RETURNS float AS $$
.sub foo_float
    .return(1.0)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar_in(varchar) RETURNS varchar AS $$
.sub foo_varchar_in
    .param string s
    .return(s)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar_out(varchar) RETURNS varchar AS $$
.sub foo_varchar_out
    $S1 = 'blue'
    .return($S1)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_char_in(char) RETURNS char AS $$
.sub foo_char_in
    .param string s
    .return(s)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_char_out(char) RETURNS char AS $$
.sub foo_char_out
    $S1 = 'b'
    .return($S1)
.end
$$ LANGUAGE plparrot;

CREATE FUNCTION test_int_float(int, float) RETURNS int AS $$
.sub foo_int_float
    .param int x
    .param num y
    .return(1)
.end
$$ LANGUAGE plparrot;


select is(test_varchar_in('cheese'::text), 'cheese', 'We can pass a varchar in');
select is(test_varchar_out('cheese'::text), 'blue', 'We can return a varchar');
select is(test_int_float(42,6.9), 1, 'We can pass an int and float as arguments');

select is(test_char_in('c'), 'c', 'We can pass a char in');
select is(test_char_out('c'), 'b', 'We can return a char');

select is(test_int_in(42),1,'We can pass in an int');
select is(test_int_out(1),42,'We can return an int');

select is(test_increment_int_int(42),43,'We can increment an int and return it');
select is(test_int(),1,'We can return an int');
select is(test_void()::text,''::text,'We can return void');
select is(test_float(), 1.0::float ,'We can return a float');

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
