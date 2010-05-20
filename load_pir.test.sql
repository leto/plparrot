begin;
-- handler function
CREATE FUNCTION plparrotu_call_handler ()
RETURNS language_handler AS '$libdir/plparrotu' LANGUAGE C;

-- language
CREATE LANGUAGE plparrotu HANDLER plparrotu_call_handler;

create or replace function plp_test() RETURNS VOID language plparrotu as $$
    syntax error
    my name is 'fred'
  $P0 = open '/tmp/testfile.plparrotu.txt', 'w'
  print $P0, 'Nobody expects this to work'
  close $P0
$$;

select plp_test();
rollback;
