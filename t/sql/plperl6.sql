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
SELECT plan(10);

CREATE OR REPLACE FUNCTION test_void_plperl6(integer) RETURNS void LANGUAGE plperl6 AS $$
Nil
$$;

CREATE OR REPLACE FUNCTION test_int_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
42
$$;

CREATE OR REPLACE FUNCTION test_arguments_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
@_[0]
$$;

CREATE OR REPLACE FUNCTION test_defined_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
@_[0].defined
$$;

CREATE OR REPLACE FUNCTION test_2arguments_plperl6(integer,integer) RETURNS int LANGUAGE plperl6 AS $$
@_.elems
$$;

CREATE OR REPLACE FUNCTION test_fibonacci_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
my $limit = @_[0];
[+] (1, 1, *+* ... $limit)
$$;

CREATE OR REPLACE FUNCTION test_named_pointy(integer, integer, integer) RETURNS int LANGUAGE plperl6 AS $$
-> $a, $b, $c {
    return $a * $b * $c;
}(|@_);
$$;

CREATE OR REPLACE FUNCTION test_float_plperl6(integer) RETURNS float AS $$ 5.0 $$ LANGUAGE plperl6;

CREATE OR REPLACE FUNCTION test_string_plperl6() RETURNS varchar AS $$ "rakudo" $$ LANGUAGE plperl6;

CREATE OR REPLACE FUNCTION test_singlequote_plperl6() RETURNS varchar AS $$ 'rakudo*' $$ LANGUAGE plperl6;

select is(test_int_plperl6(89),42,'Return an integer from PL/Perl6');
select is(test_void_plperl6(42)::text,''::text,'Return nothing from PL/Perl6');
select is(test_float_plperl6(2), 5.0::float,'Return a float from PL/Perl6');
select is(test_string_plperl6(), 'rakudo','Return a varchar from PL/Perl6');
select is(test_singlequote_plperl6(), 'rakudo*','Use a single quote in a PL/Perl6 procedure');

select is(test_fibonacci_plperl6(100),232,'Calculate the sum of all Fibonacci numbers <= 100');
select is(test_arguments_plperl6(5),5,'We can return an argument unchanged');
select is(test_defined_plperl6(100),1,'@_[0] is defined when an argument is passed in');
select is(test_2arguments_plperl6(4,9),2,'PL/Perl sees multiple arguments');

select is(test_named_pointy(10,20,30), 6000, 'Pointy blocks with named parameters work');

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
