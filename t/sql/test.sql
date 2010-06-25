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
SELECT plan(31);

CREATE OR REPLACE FUNCTION create_plparrot()
RETURNS BOOLEAN
LANGUAGE SQL
AS $$
CREATE LANGUAGE plparrot;
SELECT true;
$$;

CREATE FUNCTION test_void() RETURNS void AS $$
    .return()
$$ LANGUAGE plparrot;

CREATE FUNCTION test_int() RETURNS int AS $$
    .return(1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_int_in(int) RETURNS int AS $$
    .param int x
    .return(1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_plpir(int) RETURNS int LANGUAGE plpir AS $$
    .param int x
    .return(1)
$$;

CREATE FUNCTION test_plpiru(int) RETURNS int LANGUAGE plpiru AS $$
    .param int x
    .return(42)
$$;

CREATE FUNCTION test_plparrotu(int) RETURNS int LANGUAGE plparrotu AS $$
    .param int x
    .return(42)
$$;

CREATE FUNCTION test_immutable(int) RETURNS int AS $$
    .param int x
    .return(1)
$$ LANGUAGE plparrot IMMUTABLE;

CREATE FUNCTION test_int_out(int) RETURNS int AS $$
    .param int x
    .return(42)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_increment_int_int(int) RETURNS int AS $$
    .param int x
    inc x
    .return(x)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_strict(int) RETURNS int AS $$
    .param int x
    inc x
    .return(x)
$$ LANGUAGE plparrot STRICT;

CREATE FUNCTION test_float() RETURNS float AS $$
    $N0 = 1.0
    .return($N0)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_float_add(float) RETURNS float AS $$
    .param num x
    x += 5
    .return(x)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_text_in(text) RETURNS text AS $$
    .param string s
    .return(s)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_text_out(text) RETURNS text AS $$
    $S1 = 'blue'
    .return($S1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar_in(varchar) RETURNS varchar AS $$
    .param string s
    .return(s)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar_out(varchar) RETURNS varchar AS $$
    $S1 = 'blue'
    .return($S1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_varchar_out_concat(varchar) RETURNS varchar AS $$
    $S1 = 'red'
    $S2 = 'fish'
    $S3 = $S1 . $S2
    .return($S3)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_char_in(char) RETURNS char AS $$
    .param string s
    .return(s)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_char_out(char) RETURNS char AS $$
    $S1 = 'b'
    .return($S1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_int_float(int, float) RETURNS int AS $$
    .param int x
    .param num y
    .return(1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_timestamp_in(timestamp) RETURNS int AS $$
    .param num x
    .return(1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_timestamp_out(timestamp) RETURNS timestamp AS $$
    .param num x
    .return(x)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_timestamptz_in(timestamp with time zone) RETURNS int AS $$
    .param num x
    .return(1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_timestamptz_out(timestamp with time zone) RETURNS timestamp with time zone AS $$
    .param num x
    .return(x)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_time_in(time) RETURNS int AS $$
    .param num x
    .return(1)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_time_out(time) RETURNS time AS $$
    .param num x
    .return(x)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_open() RETURNS int AS $$
    $P0 = open "zanzibar", 'r'
    .return($P0)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_open_plparrotu() RETURNS int AS $$
    push_eh got_error
    $P0 = open "somejunkthatdoesntexist", 'r'
    pop_eh
    .return(42)
  got_error:
    .return(-1)
$$ LANGUAGE plparrotu;

CREATE FUNCTION test_filehandle_open() RETURNS int AS $$
    $P1 = new 'FileHandle'
    $P0 = $P1.'open'("stuff", 'r')
    .return($P0)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_filehandle_open_plpiru() RETURNS int AS $$
    $P1 = new 'FileHandle'
    push_eh throws_error
    $P0 = $P1.'open'("thisstuffisnthere", 'r')
    pop_eh
    .return($P0)
 throws_error:
    .return(1)
$$ LANGUAGE plpiru;

CREATE FUNCTION test_file_open() RETURNS int AS $$
    $P1 = new 'File'
    $P0 = $P1.'open'("blah", 'r')
    .return($P0)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_load_pir_library() RETURNS int AS $$
    .include 'test_more.pir'
    .return(5)
$$ LANGUAGE plparrot;

CREATE FUNCTION test_load_pbc_library() RETURNS int AS $$
    load_bytecode 'config.pbc'
    .return(5)
$$ LANGUAGE plparrot;

select is(test_load_pir_library(), 5, 'we can .include PIR libraries included with Parrot');
select is(test_load_pbc_library(), 5, 'we can load_bytecode PBC libraries included with Parrot');


-- io opcodes codes not loaded currently
--select is(test_open(), 42, 'open opcode is mocked');
select is(test_filehandle_open(), 42, 'FileHandle.open is mocked in PL/PIR');
select is(test_filehandle_open_plpiru(), 1, 'FileHandle.open is not mocked in PL/PIRU');


select is(test_file_open(), 42, 'File.open is mocked');

select is(test_text_in('cheese'), 'cheese', 'We can pass a text in');
select is(test_text_out('cheese'), 'blue', 'We can return a text');

select is(test_varchar_in('cheese'), 'cheese', 'We can pass a varchar in');
select is(test_varchar_out('cheese'), 'blue', 'We can return a varchar');

select is(test_varchar_out_concat('stuff'), 'redfish', 'We can concat and return a varchar');

select is(test_int_float(42,6.9), 1, 'We can pass an int and float as arguments');

select is(test_char_in('c'), 'c', 'We can pass a char in');
select is(test_char_out('c'), 'b', 'We can return a char');

select is(test_int_in(42),1,'We can pass in an int');
select is(test_int_out(1),42,'We can return an int');

select is(test_plpir(1),1,'plpir is an alias for plparrot');

-- Why does this fail? What happens to the return value?
select is(test_plpiru(1),42,'plpiru can return values');
select is(test_plparrotu(1),42,'plparrotu can return values');

select is(test_immutable(42),1,'Immutable works');
select is(test_strict(NULL), NULL, 'Strict works');

select is(test_increment_int_int(42),43,'We can increment an int and return it');
select is(test_int(),1,'We can return an int');
select is(test_void()::text,''::text,'We can return void');
select is(test_float(), 1.0::float ,'We can return a float');
select is(test_float_add(42), 47.0::float ,'We can add to a float and return it');

-- These do not test the fact that the timestamp datatype cannot be used from PIR
select is(test_timestamp_in('1999-01-08 04:05:06'),1,'We can pass a timestamp in');
select is(test_timestamp_out('1999-01-08 04:05:06'),'1999-01-08 04:05:06','We can return a timestamp');

-- These do not test the fact that the timestamptz datatype cannot be used from PIR
select is(test_timestamptz_in('1999-01-08 04:05:06+02'),1,'We can pass a timestamptz in');
select is(test_timestamptz_out('1999-01-08 04:05:06+02'),'1999-01-08 04:05:06+02','We can return a timestamptz');

-- These do not test the fact that the time datatype cannot be used from PIR
select is(test_time_in('04:05:06'),1,'We can pass a time in');
select is(test_time_out('04:05:06'),'04:05:06','We can return a time');

-- not loading io opcodes, they are deprecated
--select isnt(test_open_plparrotu(), 42, 'open opcode is not mocked in plperlu');

-- Finish the tests and clean up.
SELECT * FROM finish();

rollback;
