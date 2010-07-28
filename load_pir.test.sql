begin;
-- handler function
CREATE OR REPLACE FUNCTION plparrot_call_handler ()
RETURNS language_handler AS '$libdir/plparrot' LANGUAGE C;

-- language
DROP LANGUAGE IF EXISTS plparrot CASCADE;
CREATE LANGUAGE plparrot HANDLER plparrot_call_handler;

create or replace function plp_test() RETURNS VOID language plparrot as $$
    syntax error
    my name is 'fred'
  $P0 = open '/tmp/testfile.plparrot.txt', 'w'
  print $P0, 'Nobody expects this to work'
  close $P0
$$;

select plp_test();
rollback;
