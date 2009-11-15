
--DROP FUNCTION plparrot_call_handler() CASCADE;
begin;

CREATE FUNCTION plparrot_call_handler() RETURNS LANGUAGE_HANDLER AS '/Users/leto/git/postgresql/contrib/plparrot/libplparrot.so' LANGUAGE C;
CREATE LANGUAGE plparrot HANDLER plparrot_call_handler;
CREATE FUNCTION test_parrot() RETURNS void AS $$ FAIL $$ LANGUAGE plparrot;

select test_parrot();
rollback;

