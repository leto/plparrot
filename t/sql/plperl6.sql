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
SELECT plan(4);

CREATE FUNCTION test_void_plperl6(integer) RETURNS void AS $$ Nil $$ LANGUAGE plperl6;

CREATE FUNCTION test_int_plperl6(integer) RETURNS int AS $$ 42 $$ LANGUAGE plperl6;

CREATE FUNCTION test_float_plperl6(integer) RETURNS float AS $$ 5.0 $$ LANGUAGE plperl6;

CREATE FUNCTION test_string_plperl6() RETURNS varchar AS $$ "rakudo" $$ LANGUAGE plperl6;

select is(test_int_plperl6(89),42,'Return an integer from PL/Perl6');
select is(test_void_plperl6(42)::text,''::text,'Return nothing from PL/Perl6');
select is(test_float_plperl6(2), 5.0::float,'Return a float from PL/Perl6');
select is(test_string_plperl6(), 'rakudo','Return a varchar from PL/Perl6');

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
