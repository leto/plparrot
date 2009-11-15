
--DROP FUNCTION plparrot_call_handler() CASCADE;
begin;

CREATE FUNCTION plparrot_call_handler() RETURNS LANGUAGE_HANDLER AS '/Users/leto/git/postgresql/contrib/plparrot/libplparrot.so' LANGUAGE C;
CREATE LANGUAGE plparrot HANDLER plparrot_call_handler;

CREATE FUNCTION test_void() RETURNS void AS $$ FAIL $$ LANGUAGE plparrot;

CREATE FUNCTION test_int() RETURNS int AS $$ 1 $$ LANGUAGE plparrot;

CREATE FUNCTION test_int_int(int) RETURNS int AS $$ $1 $$ LANGUAGE plparrot;

CREATE FUNCTION test_float() RETURNS float AS $$ 1.0 $$ LANGUAGE plparrot;


select test_void();
select test_int();
-- this returns 0 still
select test_int_int(42);

select test_float();


rollback;

