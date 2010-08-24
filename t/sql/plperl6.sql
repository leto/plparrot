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
SELECT plan(22);

CREATE OR REPLACE FUNCTION test_void_plperl6() RETURNS void LANGUAGE plperl6 AS $$
{ Nil }
$$;

CREATE OR REPLACE FUNCTION test_int_plperl6() RETURNS int LANGUAGE plperl6 AS $$
() { 42 }
$$;

CREATE OR REPLACE FUNCTION test_arguments_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
{ @_[0] }
$$;

CREATE OR REPLACE FUNCTION test_defined_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
{ @_[0].defined }
$$;

CREATE OR REPLACE FUNCTION test_defined_plperl6() RETURNS int LANGUAGE plperl6 AS $$
{ @_[0].defined }
$$;

CREATE OR REPLACE FUNCTION test_2arguments_plperl6(integer,integer) RETURNS int LANGUAGE plperl6 AS $$
{ @_.elems }
$$;

CREATE OR REPLACE FUNCTION test_fibonacci_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
(*@_) {
    my $limit = @_[0];
    [+] (1, 1, *+* ... $limit)
}
$$;

CREATE OR REPLACE FUNCTION test_named_fibonacci_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
($limit) {
    [+] (1, 1, *+* ... $limit)
}
$$;

CREATE OR REPLACE FUNCTION test_placeholder_fibonacci_plperl6(integer) RETURNS int LANGUAGE plperl6 AS $$
{
    [+] (1, 1, *+* ... $^limit)
}
$$;

CREATE OR REPLACE FUNCTION test_input_2_placeholders(integer, integer) RETURNS int LANGUAGE plperl6 AS $$
{
    return $^a * $^b - $^b;
}
$$;

CREATE OR REPLACE FUNCTION test_input_3_args(integer, integer, integer) RETURNS int LANGUAGE plperl6 AS $$
($a, $b, $c) {
    $a - $b + $c
}
$$;

CREATE OR REPLACE FUNCTION test_named_pointy(integer, integer, integer) RETURNS int LANGUAGE plperl6 AS $$
{
    -> $a, $b, $c {
        return $a * $b * $c;
    }(|@_);
}
$$;

CREATE OR REPLACE FUNCTION test_float_plperl6() RETURNS float AS $$ 
{ 5.0 }
$$ LANGUAGE plperl6;

CREATE OR REPLACE FUNCTION test_regex(varchar) RETURNS varchar LANGUAGE plperl6 AS $$
($text) {
    if $text ~~ m/ PL.Parrot / {
        return "MATCHED";
    } else {
        return "NO_MATCH";
    }
}
$$;
-- This grammar example is taken from http://perl6advent.wordpress.com/2009/12/10/day-10-a-regex-story/

CREATE OR REPLACE FUNCTION test_grammar(text) RETURNS integer LANGUAGE plperl6 AS $q$
($item) {
    # This grammar needs a 'my' because the default is 'our' i.e. package scope
    my grammar Inventory {
        regex product { \d+ }
        regex quantity { \d+ }
        regex color { \S+ }
        regex description { \N* }
        rule TOP { ^^ <product> <quantity>
                    [
                    | <description> '(' \s* <color> \s*  ')'
                    | <color> <description>
                    ]
                    $$
        }
    }
    return ?Inventory.parse($item);
}
$q$;

CREATE OR REPLACE FUNCTION test_global_grammar(text) RETURNS integer LANGUAGE plperl6 AS $q$
($item) {
    return ?Inventory.parse($item);
}
$q$;

CREATE OR REPLACE FUNCTION load_global_grammar() RETURNS void LANGUAGE plperl6 AS $q$
{
    grammar Inventory {
        regex product { \d+ }
        regex quantity { \d+ }
        regex color { \S+ }
        regex description { \N* }
        rule TOP { ^^ <product> <quantity>
                    [
                    | <description> '(' \s* <color> \s*  ')'
                    | <color> <description>
                    ]
                    $$
        }
    }
}
$q$;

CREATE OR REPLACE FUNCTION test_string_plperl6() RETURNS varchar AS $$ 
{ "rakudo" } $$ LANGUAGE plperl6;

CREATE OR REPLACE FUNCTION test_singlequote_plperl6() RETURNS varchar AS $$ 
{ 'rakudo*' } $$ LANGUAGE plperl6;

select is(test_int_plperl6(),42,'Return an integer from PL/Perl6');
select is(test_void_plperl6()::text,''::text,'Return nothing from PL/Perl6');
select is(test_float_plperl6(), 5.0::float,'Return a float from PL/Perl6');
select is(test_string_plperl6(), 'rakudo','Return a varchar from PL/Perl6');
select is(test_singlequote_plperl6(), 'rakudo*','Use a single quote in a PL/Perl6 procedure');
select is(test_input_2_placeholders(5,4), 16, 'Can take 2 integer input arguments');

select is(test_arguments_plperl6(5),5,'We can return an argument unchanged');
select is(test_defined_plperl6(100),1,'@_[0] is defined when an argument is passed in');
select is(test_defined_plperl6(),0,'@_[0] is not defined when an argument is not passed in');
select is(test_2arguments_plperl6(4,9),2,'PL/Perl sees multiple arguments');

select is(test_named_pointy(10,20,30), 6000, 'Pointy blocks with named parameters work');

select is(test_named_fibonacci_plperl6(100),232,'Calculate the sum of all Fibonacci numbers <= 100 (named variable in signature)');
select is(test_fibonacci_plperl6(100),232,'Calculate the sum of all Fibonacci numbers <= 100');
select is(test_placeholder_fibonacci_plperl6(100),232,'Calculate the sum of all Fibonacci numbers <= 100 (placeholder variable)');
select is(test_input_3_args(10,20,30), 20, 'Input 3 named args');

select is(test_regex('PL/Parrot'), 'MATCHED', 'match a regex');
select is(test_regex('PL/Pluto'), 'NO_MATCH', 'do not match a regex');

-- these tests must come before load_global_grammar()
select is(test_grammar('some junk'), 0, 'test a string that does not parse in the Inventory grammar');
select is(test_grammar('123 456 red balloon'), 1, 'test a string that parses in the Inventory grammar');
select is(test_grammar('123 456 balloons (red)'), 1, 'test a string that parses in the Inventory grammar');
select is(test_grammar(''), 0, 'empty string should not parse in the Inventory grammar');

-- load the Inventory grammar into package scope
select load_global_grammar();

select is(test_global_grammar('some junk'), 0, 'test a string that does not parse in the global Inventory grammar');
select is(test_global_grammar('123 456 red balloon'), 1, 'test a string that parses in the global Inventory grammar');
select is(test_global_grammar('123 456 balloons (red)'), 1, 'test a string that parses in the global Inventory grammar');
select is(test_global_grammar(''), 0, 'empty string should not parse in the global Inventory grammar');

SELECT language_is_trusted( 'plperl6', 'PL/Perl6 should be trusted' );

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
