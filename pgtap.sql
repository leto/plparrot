--    PL/Parrot is copyright Jonathan "Duke" Leto and friends 2009-2010
-- This code is released under the Artistic 2.0 License, see LICENSE for
-- details.

-- This could be called pgTAP Lite, it is a subset of pgTAP proper,
-- with all schema-related functions removed

-- This file defines pgTAP, a collection of functions for TAP-based unit
-- testing. It is distributed under the revised FreeBSD license. You can
-- find the original here:
--
-- http://github.com/theory/pgtap/raw/master/pgtap.sql.in
--
-- The home page for the pgTAP project is:
--
-- http://pgtap.org/

-- ## CREATE SCHEMA TAPSCHEMA;
-- ## SET search_path TO TAPSCHEMA, public;

CREATE OR REPLACE FUNCTION pg_version()
RETURNS text AS 'SELECT current_setting(''server_version'')'
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION pg_version_num()
RETURNS integer AS $$
    SELECT s.a[1]::int * 10000
           + COALESCE(substring(s.a[2] FROM '[[:digit:]]+')::int, 0) * 100
           + COALESCE(substring(s.a[3] FROM '[[:digit:]]+')::int, 0)
      FROM (
          SELECT string_to_array(current_setting('server_version'), '.') AS a
      ) AS s;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION os_name()
RETURNS TEXT AS 'SELECT ''darwin''::text;'
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION pgtap_version()
RETURNS NUMERIC AS 'SELECT 0.23;'
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION plan( integer )
RETURNS TEXT AS $$
DECLARE
    rcount INTEGER;
    cmm    text := current_setting('client_min_messages');
BEGIN
    BEGIN
        PERFORM set_config('client_min_messages', 'warning', true);
        EXECUTE '
            CREATE SEQUENCE  __tresults___numb_seq;
            CREATE SEQUENCE  __tcache___numb_seq;

            CREATE TEMP TABLE __tcache__ (
                id    integer default nextval(''__tcache___numb_seq''),
                label TEXT    NOT NULL,
                value INTEGER NOT NULL,
                note  TEXT    NOT NULL DEFAULT ''''
            );
            GRANT ALL ON TABLE __tcache__ TO PUBLIC;

            CREATE TEMP TABLE __tresults__ (
                numb   integer default nextval(''__tresults___numb_seq''),
                ok     BOOLEAN NOT NULL DEFAULT TRUE,
                aok    BOOLEAN NOT NULL DEFAULT TRUE,
                descr  TEXT    NOT NULL DEFAULT '''',
                type   TEXT    NOT NULL DEFAULT '''',
                reason TEXT    NOT NULL DEFAULT ''''
            );
            GRANT ALL ON TABLE __tresults__ TO PUBLIC;
            GRANT ALL ON TABLE __tresults___numb_seq TO PUBLIC;
        ';

    EXCEPTION WHEN duplicate_table THEN
        PERFORM set_config('client_min_messages', cmm, true);
        -- Raise an exception if there's already a plan.
        EXECUTE 'SELECT TRUE FROM __tcache__ WHERE label = ''plan''';
      GET DIAGNOSTICS rcount = ROW_COUNT;
        IF rcount > 0 THEN
           RAISE EXCEPTION 'You tried to plan twice!';
        END IF;
    END;

    PERFORM set_config('client_min_messages', cmm, true);

    -- Save the plan and return.
    PERFORM _set('plan', $1 );
    RETURN '1..' || $1;
END;
$$ LANGUAGE plpgsql strict;

CREATE OR REPLACE FUNCTION no_plan()
RETURNS SETOF boolean AS $$
BEGIN
    PERFORM plan(0);
    RETURN;
END;
$$ LANGUAGE plpgsql strict;

CREATE OR REPLACE FUNCTION _get ( text )
RETURNS integer AS $$
DECLARE
    ret integer;
BEGIN
    EXECUTE 'SELECT value FROM __tcache__ WHERE label = ' || quote_literal($1) || ' LIMIT 1' INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql strict;

CREATE OR REPLACE FUNCTION _get_latest ( text )
RETURNS integer[] AS $$
DECLARE
    ret integer[];
BEGIN
    EXECUTE 'SELECT ARRAY[ id, value] FROM __tcache__ WHERE label = ' ||
    quote_literal($1) || ' AND id = (SELECT MAX(id) FROM __tcache__ WHERE label = ' ||
    quote_literal($1) || ') LIMIT 1' INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql strict;

CREATE OR REPLACE FUNCTION _get_latest ( text, integer )
RETURNS integer AS $$
DECLARE
    ret integer;
BEGIN
    EXECUTE 'SELECT MAX(id) FROM __tcache__ WHERE label = ' ||
    quote_literal($1) || ' AND value = ' || $2 INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql strict;

CREATE OR REPLACE FUNCTION _get_note ( text )
RETURNS text AS $$
DECLARE
    ret text;
BEGIN
    EXECUTE 'SELECT note FROM __tcache__ WHERE label = ' || quote_literal($1) || ' LIMIT 1' INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql strict;

CREATE OR REPLACE FUNCTION _get_note ( integer )
RETURNS text AS $$
DECLARE
    ret text;
BEGIN
    EXECUTE 'SELECT note FROM __tcache__ WHERE id = ' || $1 || ' LIMIT 1' INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql strict;

CREATE OR REPLACE FUNCTION _set ( text, integer, text )
RETURNS integer AS $$
DECLARE
    rcount integer;
BEGIN
    EXECUTE 'UPDATE __tcache__ SET value = ' || $2
        || CASE WHEN $3 IS NULL THEN '' ELSE ', note = ' || quote_literal($3) END
        || ' WHERE label = ' || quote_literal($1);
    GET DIAGNOSTICS rcount = ROW_COUNT;
    IF rcount = 0 THEN
       RETURN _add( $1, $2, $3 );
    END IF;
    RETURN $2;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _set ( text, integer )
RETURNS integer AS $$
    SELECT _set($1, $2, '')
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION _set ( integer, integer )
RETURNS integer AS $$
BEGIN
    EXECUTE 'UPDATE __tcache__ SET value = ' || $2
        || ' WHERE id = ' || $1;
    RETURN $2;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _add ( text, integer, text )
RETURNS integer AS $$
BEGIN
    EXECUTE 'INSERT INTO __tcache__ (label, value, note) values (' ||
    quote_literal($1) || ', ' || $2 || ', ' || quote_literal(COALESCE($3, '')) || ')';
    RETURN $2;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _add ( text, integer )
RETURNS integer AS $$
    SELECT _add($1, $2, '')
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION add_result ( bool, bool, text, text, text )
RETURNS integer AS $$
BEGIN
    EXECUTE 'INSERT INTO __tresults__ ( ok, aok, descr, type, reason )
    VALUES( ' || $1 || ', '
              || $2 || ', '
              || quote_literal(COALESCE($3, '')) || ', '
              || quote_literal($4) || ', '
              || quote_literal($5) || ' )';
    RETURN currval('__tresults___numb_seq');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION num_failed ()
RETURNS INTEGER AS $$
DECLARE
    ret integer;
BEGIN
    EXECUTE 'SELECT COUNT(*)::INTEGER FROM __tresults__ WHERE ok = FALSE' INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql strict;

CREATE OR REPLACE FUNCTION _finish ( INTEGER, INTEGER, INTEGER)
RETURNS SETOF TEXT AS $$
DECLARE
    curr_test ALIAS FOR $1;
    exp_tests INTEGER := $2;
    num_faild ALIAS FOR $3;
    plural    CHAR;
BEGIN
    plural    := CASE exp_tests WHEN 1 THEN '' ELSE 's' END;

    IF curr_test IS NULL THEN
        RAISE EXCEPTION '# No tests run!';
    END IF;

    IF exp_tests = 0 OR exp_tests IS NULL THEN
         -- No plan. Output one now.
        exp_tests = curr_test;
        RETURN NEXT '1..' || exp_tests;
    END IF;

    IF curr_test <> exp_tests THEN
        RETURN NEXT diag(
            'Looks like you planned ' || exp_tests || ' test' ||
            plural || ' but ran ' || curr_test
        );
    ELSIF num_faild > 0 THEN
        RETURN NEXT diag(
            'Looks like you failed ' || num_faild || ' test' ||
            CASE num_faild WHEN 1 THEN '' ELSE 's' END
            || ' of ' || exp_tests
        );
    ELSE

    END IF;
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION finish ()
RETURNS SETOF TEXT AS $$
    SELECT * FROM _finish(
        _get('curr_test'),
        _get('plan'),
        num_failed()
    );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION diag ( msg text )
RETURNS TEXT AS $$
    SELECT '# ' || replace(
       replace(
            replace( $1, E'\r\n', E'\n# ' ),
            E'\n',
            E'\n# '
        ),
        E'\r',
        E'\n# '
    );
$$ LANGUAGE sql strict;

CREATE OR REPLACE FUNCTION ok ( boolean, text )
RETURNS TEXT AS $$
DECLARE
   aok      ALIAS FOR $1;
   descr    text := $2;
   test_num INTEGER;
   todo_why TEXT;
   ok       BOOL;
BEGIN
   todo_why := _todo();
   ok       := CASE
       WHEN aok = TRUE THEN aok
       WHEN todo_why IS NULL THEN COALESCE(aok, false)
       ELSE TRUE
    END;
    IF _get('plan') IS NULL THEN
        RAISE EXCEPTION 'You tried to run a test without a plan! Gotta have a plan';
    END IF;

    test_num := add_result(
        ok,
        COALESCE(aok, false),
        descr,
        CASE WHEN todo_why IS NULL THEN '' ELSE 'todo' END,
        COALESCE(todo_why, '')
    );

    RETURN (CASE aok WHEN TRUE THEN '' ELSE 'not ' END)
           || 'ok ' || _set( 'curr_test', test_num )
           || CASE descr WHEN '' THEN '' ELSE COALESCE( ' - ' || substr(diag( descr ), 3), '' ) END
           || COALESCE( ' ' || diag( 'TODO ' || todo_why ), '')
           || CASE aok WHEN TRUE THEN '' ELSE E'\n' ||
                diag('Failed ' ||
                CASE WHEN todo_why IS NULL THEN '' ELSE '(TODO) ' END ||
                'test ' || test_num ||
                CASE descr WHEN '' THEN '' ELSE COALESCE(': "' || descr || '"', '') END ) ||
                CASE WHEN aok IS NULL THEN E'\n' || diag('    (test result was NULL)') ELSE '' END
           END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ok ( boolean )
RETURNS TEXT AS $$
    SELECT ok( $1, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION is (anyelement, anyelement, text)
RETURNS TEXT AS $$
DECLARE
    result BOOLEAN;
    output TEXT;
BEGIN
    -- Would prefer $1 IS NOT DISTINCT FROM, but that's not supported by 8.1.
    result := NOT $1 IS DISTINCT FROM $2;
    output := ok( result, $3 );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '        have: ' || COALESCE( $1::text, 'NULL' ) ||
        E'\n        want: ' || COALESCE( $2::text, 'NULL' )
    ) END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is (anyelement, anyelement)
RETURNS TEXT AS $$
    SELECT is( $1, $2, NULL);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION isnt (anyelement, anyelement, text)
RETURNS TEXT AS $$
DECLARE
    result BOOLEAN;
    output TEXT;
BEGIN
    result := $1 IS DISTINCT FROM $2;
    output := ok( result, $3 );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '    ' || COALESCE( $1::text, 'NULL' ) ||
        E'\n      <>' ||
        E'\n    ' || COALESCE( $2::text, 'NULL' )
    ) END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION isnt (anyelement, anyelement)
RETURNS TEXT AS $$
    SELECT isnt( $1, $2, NULL);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION _alike ( BOOLEAN, ANYELEMENT, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    result ALIAS FOR $1;
    got    ALIAS FOR $2;
    rx     ALIAS FOR $3;
    descr  ALIAS FOR $4;
    output TEXT;
BEGIN
    output := ok( result, descr );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '                  ' || COALESCE( quote_literal(got), 'NULL' ) ||
       E'\n   doesn''t match: ' || COALESCE( quote_literal(rx), 'NULL' )
    ) END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION matches ( anyelement, text, text )
RETURNS TEXT AS $$
    SELECT _alike( $1 ~ $2, $1, $2, $3 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION matches ( anyelement, text )
RETURNS TEXT AS $$
    SELECT _alike( $1 ~ $2, $1, $2, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION imatches ( anyelement, text, text )
RETURNS TEXT AS $$
    SELECT _alike( $1 ~* $2, $1, $2, $3 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION imatches ( anyelement, text )
RETURNS TEXT AS $$
    SELECT _alike( $1 ~* $2, $1, $2, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION alike ( anyelement, text, text )
RETURNS TEXT AS $$
    SELECT _alike( $1 ~~ $2, $1, $2, $3 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION alike ( anyelement, text )
RETURNS TEXT AS $$
    SELECT _alike( $1 ~~ $2, $1, $2, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ialike ( anyelement, text, text )
RETURNS TEXT AS $$
    SELECT _alike( $1 ~~* $2, $1, $2, $3 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ialike ( anyelement, text )
RETURNS TEXT AS $$
    SELECT _alike( $1 ~~* $2, $1, $2, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION _unalike ( BOOLEAN, ANYELEMENT, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    result ALIAS FOR $1;
    got    ALIAS FOR $2;
    rx     ALIAS FOR $3;
    descr  ALIAS FOR $4;
    output TEXT;
BEGIN
    output := ok( result, descr );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '                  ' || COALESCE( quote_literal(got), 'NULL' ) ||
        E'\n         matches: ' || COALESCE( quote_literal(rx), 'NULL' )
    ) END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION doesnt_match ( anyelement, text, text )
RETURNS TEXT AS $$
    SELECT _unalike( $1 !~ $2, $1, $2, $3 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION doesnt_match ( anyelement, text )
RETURNS TEXT AS $$
    SELECT _unalike( $1 !~ $2, $1, $2, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION doesnt_imatch ( anyelement, text, text )
RETURNS TEXT AS $$
    SELECT _unalike( $1 !~* $2, $1, $2, $3 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION doesnt_imatch ( anyelement, text )
RETURNS TEXT AS $$
    SELECT _unalike( $1 !~* $2, $1, $2, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION unalike ( anyelement, text, text )
RETURNS TEXT AS $$
    SELECT _unalike( $1 !~~ $2, $1, $2, $3 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION unalike ( anyelement, text )
RETURNS TEXT AS $$
    SELECT _unalike( $1 !~~ $2, $1, $2, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION unialike ( anyelement, text, text )
RETURNS TEXT AS $$
    SELECT _unalike( $1 !~~* $2, $1, $2, $3 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION unialike ( anyelement, text )
RETURNS TEXT AS $$
    SELECT _unalike( $1 !~~* $2, $1, $2, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION cmp_ok (anyelement, text, anyelement, text)
RETURNS TEXT AS $$
DECLARE
    have   ALIAS FOR $1;
    op     ALIAS FOR $2;
    want   ALIAS FOR $3;
    descr  ALIAS FOR $4;
    result BOOLEAN;
    output TEXT;
BEGIN
    EXECUTE 'SELECT ' ||
            COALESCE(quote_literal( have ), 'NULL') || '::' || pg_typeof(have) || ' '
            || op || ' ' ||
            COALESCE(quote_literal( want ), 'NULL') || '::' || pg_typeof(want)
       INTO result;
    output := ok( COALESCE(result, FALSE), descr );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '    ' || COALESCE( quote_literal(have), 'NULL' ) ||
           E'\n        ' || op ||
           E'\n    ' || COALESCE( quote_literal(want), 'NULL' )
    ) END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cmp_ok (anyelement, text, anyelement)
RETURNS TEXT AS $$
    SELECT cmp_ok( $1, $2, $3, NULL );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION pass ( text )
RETURNS TEXT AS $$
    SELECT ok( TRUE, $1 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION pass ()
RETURNS TEXT AS $$
    SELECT ok( TRUE, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION fail ( text )
RETURNS TEXT AS $$
    SELECT ok( FALSE, $1 );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION fail ()
RETURNS TEXT AS $$
    SELECT ok( FALSE, NULL );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION todo ( why text, how_many int )
RETURNS SETOF BOOLEAN AS $$
BEGIN
    PERFORM _add('todo', COALESCE(how_many, 1), COALESCE(why, ''));
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION todo ( how_many int, why text )
RETURNS SETOF BOOLEAN AS $$
BEGIN
    PERFORM _add('todo', COALESCE(how_many, 1), COALESCE(why, ''));
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION todo ( why text )
RETURNS SETOF BOOLEAN AS $$
BEGIN
    PERFORM _add('todo', 1, COALESCE(why, ''));
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION todo ( how_many int )
RETURNS SETOF BOOLEAN AS $$
BEGIN
    PERFORM _add('todo', COALESCE(how_many, 1), '');
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION todo_start (text)
RETURNS SETOF BOOLEAN AS $$
BEGIN
    PERFORM _add('todo', -1, COALESCE($1, ''));
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION todo_start ()
RETURNS SETOF BOOLEAN AS $$
BEGIN
    PERFORM _add('todo', -1, '');
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION in_todo ()
RETURNS BOOLEAN AS $$
DECLARE
    todos integer;
BEGIN
    todos := _get('todo');
    RETURN CASE WHEN todos IS NULL THEN FALSE ELSE TRUE END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION todo_end ()
RETURNS SETOF BOOLEAN AS $$
DECLARE
    id integer;
BEGIN
    id := _get_latest( 'todo', -1 );
    IF id IS NULL THEN
        RAISE EXCEPTION 'todo_end() called without todo_start()';
    END IF;
    EXECUTE 'DELETE FROM __tcache__ WHERE id = ' || id;
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _todo()
RETURNS TEXT AS $$
DECLARE
    todos INT[];
    note text;
BEGIN
    -- Get the latest id and value, because todo() might have been called
    -- again before the todos ran out for the first call to todo(). This
    -- allows them to nest.
    todos := _get_latest('todo');
    IF todos IS NULL THEN
        -- No todos.
        RETURN NULL;
    END IF;
    IF todos[2] = 0 THEN
        -- Todos depleted. Clean up.
        EXECUTE 'DELETE FROM __tcache__ WHERE id = ' || todos[1];
        RETURN NULL;
    END IF;
    -- Decrement the count of counted todos and return the reason.
    IF todos[2] <> -1 THEN
        PERFORM _set(todos[1], todos[2] - 1);
    END IF;
    note := _get_note(todos[1]);

    IF todos[2] = 1 THEN
        -- This was the last todo, so delete the record.
        EXECUTE 'DELETE FROM __tcache__ WHERE id = ' || todos[1];
    END IF;

    RETURN note;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION skip ( why text, how_many int )
RETURNS TEXT AS $$
DECLARE
    output TEXT[];
BEGIN
    output := '{}';
    FOR i IN 1..how_many LOOP
        output = array_append(output, ok( TRUE, 'SKIP: ' || COALESCE( why, '') ) );
    END LOOP;
    RETURN array_to_string(output, E'\n');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION skip ( text )
RETURNS TEXT AS $$
    SELECT ok( TRUE, 'SKIP: ' || $1 );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION skip( int, text )
RETURNS TEXT AS 'SELECT skip($2, $1)'
LANGUAGE sql;

CREATE OR REPLACE FUNCTION skip( int )
RETURNS TEXT AS 'SELECT skip(NULL, $1)'
LANGUAGE sql;

CREATE OR REPLACE FUNCTION _query( TEXT )
RETURNS TEXT AS $$
    SELECT CASE
        WHEN $1 LIKE '"%' OR $1 !~ '[[:space:]]' THEN 'EXECUTE ' || $1
        ELSE $1
    END;
$$ LANGUAGE SQL;

-- throws_ok ( sql, errcode, errmsg, description )
CREATE OR REPLACE FUNCTION throws_ok ( TEXT, CHAR(5), TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    query     TEXT := _query($1);
    errcode   ALIAS FOR $2;
    errmsg    ALIAS FOR $3;
    desctext  ALIAS FOR $4;
    descr     TEXT;
BEGIN
    descr := COALESCE(
          desctext,
          'threw ' || errcode || ': ' || errmsg,
          'threw ' || errcode,
          'threw ' || errmsg,
          'threw an exception'
    );
    EXECUTE query;
    RETURN ok( FALSE, descr ) || E'\n' || diag(
           '      caught: no exception' ||
        E'\n      wanted: ' || COALESCE( errcode, 'an exception' )
    );
EXCEPTION WHEN OTHERS THEN
    IF (errcode IS NULL OR SQLSTATE = errcode)
        AND ( errmsg IS NULL OR SQLERRM = errmsg)
    THEN
        -- The expected errcode and/or message was thrown.
        RETURN ok( TRUE, descr );
    ELSE
        -- This was not the expected errcodeor.
        RETURN ok( FALSE, descr ) || E'\n' || diag(
               '      caught: ' || SQLSTATE || ': ' || SQLERRM ||
            E'\n      wanted: ' || COALESCE( errcode, 'an exception' ) ||
            COALESCE( ': ' || errmsg, '')
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- throws_ok ( sql, errcode, errmsg )
-- throws_ok ( sql, errmsg, description )
CREATE OR REPLACE FUNCTION throws_ok ( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
BEGIN
    IF octet_length($2) = 5 THEN
        RETURN throws_ok( $1, $2::char(5), $3, NULL );
    ELSE
        RETURN throws_ok( $1, NULL, $2, $3 );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- throws_ok ( query, errcode )
-- throws_ok ( query, errmsg )
CREATE OR REPLACE FUNCTION throws_ok ( TEXT, TEXT )
RETURNS TEXT AS $$
BEGIN
    IF octet_length($2) = 5 THEN
        RETURN throws_ok( $1, $2::char(5), NULL, NULL );
    ELSE
        RETURN throws_ok( $1, NULL, $2, NULL );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- throws_ok ( sql )
CREATE OR REPLACE FUNCTION throws_ok ( TEXT )
RETURNS TEXT AS $$
    SELECT throws_ok( $1, NULL, NULL, NULL );
$$ LANGUAGE SQL;

-- Magically cast integer error codes.
-- throws_ok ( sql, errcode, errmsg, description )
CREATE OR REPLACE FUNCTION throws_ok ( TEXT, int4, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT throws_ok( $1, $2::char(5), $3, $4 );
$$ LANGUAGE SQL;

-- throws_ok ( sql, errcode, errmsg )
CREATE OR REPLACE FUNCTION throws_ok ( TEXT, int4, TEXT )
RETURNS TEXT AS $$
    SELECT throws_ok( $1, $2::char(5), $3, NULL );
$$ LANGUAGE SQL;

-- throws_ok ( sql, errcode )
CREATE OR REPLACE FUNCTION throws_ok ( TEXT, int4 )
RETURNS TEXT AS $$
    SELECT throws_ok( $1, $2::char(5), NULL, NULL );
$$ LANGUAGE SQL;

-- lives_ok( sql, description )
CREATE OR REPLACE FUNCTION lives_ok ( TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    code  TEXT := _query($1);
    descr ALIAS FOR $2;
BEGIN
    EXECUTE code;
    RETURN ok( TRUE, descr );
EXCEPTION WHEN OTHERS THEN
    -- There should have been no exception.
    RETURN ok( FALSE, descr ) || E'\n' || diag(
           '        died: ' || SQLSTATE || ': ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- lives_ok( sql )
CREATE OR REPLACE FUNCTION lives_ok ( TEXT )
RETURNS TEXT AS $$
    SELECT lives_ok( $1, NULL );
$$ LANGUAGE SQL;

-- performs_ok ( sql, milliseconds, description )
CREATE OR REPLACE FUNCTION performs_ok ( TEXT, NUMERIC, TEXT )
RETURNS TEXT AS $$
DECLARE
    query     TEXT := _query($1);
    max_time  ALIAS FOR $2;
    descr     ALIAS FOR $3;
    starts_at TEXT;
    act_time  NUMERIC;
BEGIN
    starts_at := timeofday();
    EXECUTE query;
    act_time := extract( millisecond from timeofday()::timestamptz - starts_at::timestamptz);
    IF act_time < max_time THEN RETURN ok(TRUE, descr); END IF;
    RETURN ok( FALSE, descr ) || E'\n' || diag(
           '      runtime: ' || act_time || ' ms' ||
        E'\n      exceeds: ' || max_time || ' ms'
    );
END;
$$ LANGUAGE plpgsql;

-- performs_ok ( sql, milliseconds )
CREATE OR REPLACE FUNCTION performs_ok ( TEXT, NUMERIC )
RETURNS TEXT AS $$
    SELECT performs_ok(
        $1, $2, 'Should run in less than ' || $2 || ' ms'
    );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION _rexists ( CHAR, NAME, NAME )
RETURNS BOOLEAN AS $$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
         WHERE c.relkind = $1
           AND n.nspname = $2
           AND c.relname = $3
    );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION _rexists ( CHAR, NAME )
RETURNS BOOLEAN AS $$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_class c
         WHERE c.relkind = $1
           AND pg_catalog.pg_table_is_visible(c.oid)
           AND c.relname = $2
    );
$$ LANGUAGE SQL;

 
CREATE OR REPLACE FUNCTION has_table ( NAME, NAME, TEXT )
RETURNS TEXT AS $$
    SELECT ok( _rexists( 'r', $1, $2 ), $3 );
$$ LANGUAGE SQL;

-- has_table( table, description )
CREATE OR REPLACE FUNCTION has_table ( NAME, TEXT )
RETURNS TEXT AS $$
    SELECT ok( _rexists( 'r', $1 ), $2 );
$$ LANGUAGE SQL;

-- has_table( table )
CREATE OR REPLACE FUNCTION has_table ( NAME )
RETURNS TEXT AS $$
    SELECT has_table( $1, 'Table ' || quote_ident($1) || ' should exist' );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION _temptable ( TEXT, TEXT )
RETURNS TEXT AS $$
BEGIN
    EXECUTE 'CREATE TEMP TABLE ' || $2 || ' AS ' || _query($1);
    return $2;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _temptable ( anyarray, TEXT )
RETURNS TEXT AS $$
BEGIN
    CREATE TEMP TABLE _____coltmp___ AS
    SELECT $1[i]
    FROM generate_series(array_lower($1, 1), array_upper($1, 1)) s(i);
    EXECUTE 'ALTER TABLE _____coltmp___ RENAME TO ' || $2;
    return $2;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION _docomp( TEXT, TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    have    ALIAS FOR $1;
    want    ALIAS FOR $2;
    extras  TEXT[]  := '{}';
    missing TEXT[]  := '{}';
    res     BOOLEAN := TRUE;
    msg     TEXT    := '';
    rec     RECORD;
BEGIN
    BEGIN
        -- Find extra records.
        FOR rec in EXECUTE 'SELECT * FROM ' || have || ' EXCEPT ' || $4
                        || 'SELECT * FROM ' || want LOOP
            extras := extras || rec::text;
        END LOOP;

        -- Find missing records.
        FOR rec in EXECUTE 'SELECT * FROM ' || want || ' EXCEPT ' || $4
                        || 'SELECT * FROM ' || have LOOP
            missing := missing || rec::text;
        END LOOP;

        -- Drop the temporary tables.
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
    EXCEPTION WHEN syntax_error OR datatype_mismatch THEN
        msg := E'\n' || diag(
            E'    Columns differ between queries:\n'
            || '        have: (' || _temptypes(have) || E')\n'
            || '        want: (' || _temptypes(want) || ')'
        );
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
        RETURN ok(FALSE, $3) || msg;
    END;

    -- What extra records do we have?
    IF extras[1] IS NOT NULL THEN
        res := FALSE;
        msg := E'\n' || diag(
            E'    Extra records:\n        '
            ||  array_to_string( extras, E'\n        ' )
        );
    END IF;

    -- What missing records do we have?
    IF missing[1] IS NOT NULL THEN
        res := FALSE;
        msg := msg || E'\n' || diag(
            E'    Missing records:\n        '
            ||  array_to_string( missing, E'\n        ' )
        );
    END IF;

    RETURN ok(res, $3) || msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _relcomp( TEXT, TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _docomp(
        _temptable( $1, '__taphave__' ),
        _temptable( $2, '__tapwant__' ),
        $3, $4
    );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION _relcomp( TEXT, anyarray, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _docomp(
        _temptable( $1, '__taphave__' ),
        _temptable( $2, '__tapwant__' ),
        $3, $4
    );
$$ LANGUAGE sql;

-- set_eq( sql, sql, description )
CREATE OR REPLACE FUNCTION set_eq( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, $3, '' );
$$ LANGUAGE sql;

-- set_eq( sql, sql )
CREATE OR REPLACE FUNCTION set_eq( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, NULL::text, '' );
$$ LANGUAGE sql;

-- set_eq( sql, array, description )
CREATE OR REPLACE FUNCTION set_eq( TEXT, anyarray, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, $3, '' );
$$ LANGUAGE sql;

-- set_eq( sql, array )
CREATE OR REPLACE FUNCTION set_eq( TEXT, anyarray )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, NULL::text, '' );
$$ LANGUAGE sql;

-- bag_eq( sql, sql, description )
CREATE OR REPLACE FUNCTION bag_eq( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, $3, 'ALL ' );
$$ LANGUAGE sql;

-- bag_eq( sql, sql )
CREATE OR REPLACE FUNCTION bag_eq( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, NULL::text, 'ALL ' );
$$ LANGUAGE sql;

-- bag_eq( sql, array, description )
CREATE OR REPLACE FUNCTION bag_eq( TEXT, anyarray, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, $3, 'ALL ' );
$$ LANGUAGE sql;

-- bag_eq( sql, array )
CREATE OR REPLACE FUNCTION bag_eq( TEXT, anyarray )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, NULL::text, 'ALL ' );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION _do_ne( TEXT, TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    have    ALIAS FOR $1;
    want    ALIAS FOR $2;
    extras  TEXT[]  := '{}';
    missing TEXT[]  := '{}';
    res     BOOLEAN := TRUE;
    msg     TEXT    := '';
BEGIN
    BEGIN
        -- Find extra records.
        EXECUTE 'SELECT EXISTS ( '
             || '( SELECT * FROM ' || have || ' EXCEPT ' || $4
             || '  SELECT * FROM ' || want
             || ' ) UNION ( '
             || '  SELECT * FROM ' || want || ' EXCEPT ' || $4
             || '  SELECT * FROM ' || have
             || ' ) LIMIT 1 )' INTO res;

        -- Drop the temporary tables.
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
    EXCEPTION WHEN syntax_error OR datatype_mismatch THEN
        msg := E'\n' || diag(
            E'    Columns differ between queries:\n'
            || '        have: (' || _temptypes(have) || E')\n'
            || '        want: (' || _temptypes(want) || ')'
        );
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
        RETURN ok(FALSE, $3) || msg;
    END;

    -- Return the value from the query.
    RETURN ok(res, $3);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _relne( TEXT, TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _do_ne(
        _temptable( $1, '__taphave__' ),
        _temptable( $2, '__tapwant__' ),
        $3, $4
    );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION _relne( TEXT, anyarray, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _do_ne(
        _temptable( $1, '__taphave__' ),
        _temptable( $2, '__tapwant__' ),
        $3, $4
    );
$$ LANGUAGE sql;

-- set_ne( sql, sql, description )
CREATE OR REPLACE FUNCTION set_ne( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relne( $1, $2, $3, '' );
$$ LANGUAGE sql;

-- set_ne( sql, sql )
CREATE OR REPLACE FUNCTION set_ne( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relne( $1, $2, NULL::text, '' );
$$ LANGUAGE sql;

-- set_ne( sql, array, description )
CREATE OR REPLACE FUNCTION set_ne( TEXT, anyarray, TEXT )
RETURNS TEXT AS $$
    SELECT _relne( $1, $2, $3, '' );
$$ LANGUAGE sql;

-- set_ne( sql, array )
CREATE OR REPLACE FUNCTION set_ne( TEXT, anyarray )
RETURNS TEXT AS $$
    SELECT _relne( $1, $2, NULL::text, '' );
$$ LANGUAGE sql;

-- bag_ne( sql, sql, description )
CREATE OR REPLACE FUNCTION bag_ne( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relne( $1, $2, $3, 'ALL ' );
$$ LANGUAGE sql;

-- bag_ne( sql, sql )
CREATE OR REPLACE FUNCTION bag_ne( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relne( $1, $2, NULL::text, 'ALL ' );
$$ LANGUAGE sql;

-- bag_ne( sql, array, description )
CREATE OR REPLACE FUNCTION bag_ne( TEXT, anyarray, TEXT )
RETURNS TEXT AS $$
    SELECT _relne( $1, $2, $3, 'ALL ' );
$$ LANGUAGE sql;

-- bag_ne( sql, array )
CREATE OR REPLACE FUNCTION bag_ne( TEXT, anyarray )
RETURNS TEXT AS $$
    SELECT _relne( $1, $2, NULL::text, 'ALL ' );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION _relcomp( TEXT, TEXT, TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    have    TEXT    := _temptable( $1, '__taphave__' );
    want    TEXT    := _temptable( $2, '__tapwant__' );
    results TEXT[]  := '{}';
    res     BOOLEAN := TRUE;
    msg     TEXT    := '';
    rec     RECORD;
BEGIN
    BEGIN
        -- Find relevant records.
        FOR rec in EXECUTE 'SELECT * FROM ' || want || ' ' || $4
                       || ' SELECT * FROM ' || have LOOP
            results := results || rec::text;
        END LOOP;

        -- Drop the temporary tables.
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
    EXCEPTION WHEN syntax_error OR datatype_mismatch THEN
        msg := E'\n' || diag(
            E'    Columns differ between queries:\n'
            || '        have: (' || _temptypes(have) || E')\n'
            || '        want: (' || _temptypes(want) || ')'
        );
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
        RETURN ok(FALSE, $3) || msg;
    END;

    -- What records do we have?
    IF results[1] IS NOT NULL THEN
        res := FALSE;
        msg := msg || E'\n' || diag(
            '    ' || $5 || E' records:\n        '
            ||  array_to_string( results, E'\n        ' )
        );
    END IF;

    RETURN ok(res, $3) || msg;
END;
$$ LANGUAGE plpgsql;

-- set_has( sql, sql, description )
CREATE OR REPLACE FUNCTION set_has( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, $3, 'EXCEPT', 'Missing' );
$$ LANGUAGE sql;

-- set_has( sql, sql )
CREATE OR REPLACE FUNCTION set_has( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, NULL::TEXT, 'EXCEPT', 'Missing' );
$$ LANGUAGE sql;

-- bag_has( sql, sql, description )
CREATE OR REPLACE FUNCTION bag_has( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, $3, 'EXCEPT ALL', 'Missing' );
$$ LANGUAGE sql;

-- bag_has( sql, sql )
CREATE OR REPLACE FUNCTION bag_has( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, NULL::TEXT, 'EXCEPT ALL', 'Missing' );
$$ LANGUAGE sql;

-- set_hasnt( sql, sql, description )
CREATE OR REPLACE FUNCTION set_hasnt( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, $3, 'INTERSECT', 'Extra' );
$$ LANGUAGE sql;

-- set_hasnt( sql, sql )
CREATE OR REPLACE FUNCTION set_hasnt( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, NULL::TEXT, 'INTERSECT', 'Extra' );
$$ LANGUAGE sql;

-- bag_hasnt( sql, sql, description )
CREATE OR REPLACE FUNCTION bag_hasnt( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, $3, 'INTERSECT ALL', 'Extra' );
$$ LANGUAGE sql;

-- bag_hasnt( sql, sql )
CREATE OR REPLACE FUNCTION bag_hasnt( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT _relcomp( $1, $2, NULL::TEXT, 'INTERSECT ALL', 'Extra' );
$$ LANGUAGE sql;

-- results_eq( cursor, cursor, description )
CREATE OR REPLACE FUNCTION results_eq( refcursor, refcursor, text )
RETURNS TEXT AS $$
DECLARE
    have       ALIAS FOR $1;
    want       ALIAS FOR $2;
    have_rec   RECORD;
    want_rec   RECORD;
    have_found BOOLEAN;
    want_found BOOLEAN;
    rownum     INTEGER := 1;
BEGIN
    FETCH have INTO have_rec;
    have_found := FOUND;
    FETCH want INTO want_rec;
    want_found := FOUND;
    WHILE have_found OR want_found LOOP
        IF have_rec IS DISTINCT FROM want_rec OR have_found <> want_found THEN
            RETURN ok( false, $3 ) || E'\n' || diag(
                '    Results differ beginning at row ' || rownum || E':\n' ||
                '        have: ' || CASE WHEN have_found THEN have_rec::text ELSE 'NULL' END || E'\n' ||
                '        want: ' || CASE WHEN want_found THEN want_rec::text ELSE 'NULL' END
            );
        END IF;
        rownum = rownum + 1;
        FETCH have INTO have_rec;
        have_found := FOUND;
        FETCH want INTO want_rec;
        want_found := FOUND;
    END LOOP;

    RETURN ok( true, $3 );
EXCEPTION
    WHEN datatype_mismatch THEN
        RETURN ok( false, $3 ) || E'\n' || diag(
            E'    Columns differ between queries:\n' ||
            '        have: ' || CASE WHEN have_found THEN have_rec::text ELSE 'NULL' END || E'\n' ||
            '        want: ' || CASE WHEN want_found THEN want_rec::text ELSE 'NULL' END
        );
END;
$$ LANGUAGE plpgsql;

-- results_eq( cursor, cursor )
CREATE OR REPLACE FUNCTION results_eq( refcursor, refcursor )
RETURNS TEXT AS $$
    SELECT results_eq( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_eq( sql, sql, description )
CREATE OR REPLACE FUNCTION results_eq( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    have REFCURSOR;
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    OPEN want FOR EXECUTE _query($2);
    res := results_eq(have, want, $3);
    CLOSE have;
    CLOSE want;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_eq( sql, sql )
CREATE OR REPLACE FUNCTION results_eq( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT results_eq( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_eq( sql, array, description )
CREATE OR REPLACE FUNCTION results_eq( TEXT, anyarray, TEXT )
RETURNS TEXT AS $$
DECLARE
    have REFCURSOR;
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    OPEN want FOR SELECT $2[i]
    FROM generate_series(array_lower($2, 1), array_upper($2, 1)) s(i);
    res := results_eq(have, want, $3);
    CLOSE have;
    CLOSE want;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_eq( sql, array )
CREATE OR REPLACE FUNCTION results_eq( TEXT, anyarray )
RETURNS TEXT AS $$
    SELECT results_eq( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_eq( sql, cursor, description )
CREATE OR REPLACE FUNCTION results_eq( TEXT, refcursor, TEXT )
RETURNS TEXT AS $$
DECLARE
    have REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    res := results_eq(have, $2, $3);
    CLOSE have;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_eq( sql, cursor )
CREATE OR REPLACE FUNCTION results_eq( TEXT, refcursor )
RETURNS TEXT AS $$
    SELECT results_eq( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_eq( cursor, sql, description )
CREATE OR REPLACE FUNCTION results_eq( refcursor, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN want FOR EXECUTE _query($2);
    res := results_eq($1, want, $3);
    CLOSE want;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_eq( cursor, sql )
CREATE OR REPLACE FUNCTION results_eq( refcursor, TEXT )
RETURNS TEXT AS $$
    SELECT results_eq( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_eq( cursor, array, description )
CREATE OR REPLACE FUNCTION results_eq( refcursor, anyarray, TEXT )
RETURNS TEXT AS $$
DECLARE
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN want FOR SELECT $2[i]
    FROM generate_series(array_lower($2, 1), array_upper($2, 1)) s(i);
    res := results_eq($1, want, $3);
    CLOSE want;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_eq( cursor, array )
CREATE OR REPLACE FUNCTION results_eq( refcursor, anyarray )
RETURNS TEXT AS $$
    SELECT results_eq( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_ne( cursor, cursor, description )
CREATE OR REPLACE FUNCTION results_ne( refcursor, refcursor, text )
RETURNS TEXT AS $$
DECLARE
    have       ALIAS FOR $1;
    want       ALIAS FOR $2;
    have_rec   RECORD;
    want_rec   RECORD;
    have_found BOOLEAN;
    want_found BOOLEAN;
BEGIN
    FETCH have INTO have_rec;
    have_found := FOUND;
    FETCH want INTO want_rec;
    want_found := FOUND;
    WHILE have_found OR want_found LOOP
        IF have_rec IS DISTINCT FROM want_rec OR have_found <> want_found THEN
            RETURN ok( true, $3 );
        ELSE
            FETCH have INTO have_rec;
            have_found := FOUND;
            FETCH want INTO want_rec;
            want_found := FOUND;
        END IF;
    END LOOP;
    RETURN ok( false, $3 );
EXCEPTION
    WHEN datatype_mismatch THEN
        RETURN ok( false, $3 ) || E'\n' || diag(
            E'    Columns differ between queries:\n' ||
            '        have: ' || CASE WHEN have_found THEN have_rec::text ELSE 'NULL' END || E'\n' ||
            '        want: ' || CASE WHEN want_found THEN want_rec::text ELSE 'NULL' END
        );
END;
$$ LANGUAGE plpgsql;

-- results_ne( cursor, cursor )
CREATE OR REPLACE FUNCTION results_ne( refcursor, refcursor )
RETURNS TEXT AS $$
    SELECT results_ne( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_ne( sql, sql, description )
CREATE OR REPLACE FUNCTION results_ne( TEXT, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    have REFCURSOR;
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    OPEN want FOR EXECUTE _query($2);
    res := results_ne(have, want, $3);
    CLOSE have;
    CLOSE want;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_ne( sql, sql )
CREATE OR REPLACE FUNCTION results_ne( TEXT, TEXT )
RETURNS TEXT AS $$
    SELECT results_ne( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_ne( sql, array, description )
CREATE OR REPLACE FUNCTION results_ne( TEXT, anyarray, TEXT )
RETURNS TEXT AS $$
DECLARE
    have REFCURSOR;
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    OPEN want FOR SELECT $2[i]
    FROM generate_series(array_lower($2, 1), array_upper($2, 1)) s(i);
    res := results_ne(have, want, $3);
    CLOSE have;
    CLOSE want;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_ne( sql, array )
CREATE OR REPLACE FUNCTION results_ne( TEXT, anyarray )
RETURNS TEXT AS $$
    SELECT results_ne( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_ne( sql, cursor, description )
CREATE OR REPLACE FUNCTION results_ne( TEXT, refcursor, TEXT )
RETURNS TEXT AS $$
DECLARE
    have REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    res := results_ne(have, $2, $3);
    CLOSE have;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_ne( sql, cursor )
CREATE OR REPLACE FUNCTION results_ne( TEXT, refcursor )
RETURNS TEXT AS $$
    SELECT results_ne( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_ne( cursor, sql, description )
CREATE OR REPLACE FUNCTION results_ne( refcursor, TEXT, TEXT )
RETURNS TEXT AS $$
DECLARE
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN want FOR EXECUTE _query($2);
    res := results_ne($1, want, $3);
    CLOSE want;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_ne( cursor, sql )
CREATE OR REPLACE FUNCTION results_ne( refcursor, TEXT )
RETURNS TEXT AS $$
    SELECT results_ne( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- results_ne( cursor, array, description )
CREATE OR REPLACE FUNCTION results_ne( refcursor, anyarray, TEXT )
RETURNS TEXT AS $$
DECLARE
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN want FOR SELECT $2[i]
    FROM generate_series(array_lower($2, 1), array_upper($2, 1)) s(i);
    res := results_ne($1, want, $3);
    CLOSE want;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- results_ne( cursor, array )
CREATE OR REPLACE FUNCTION results_ne( refcursor, anyarray )
RETURNS TEXT AS $$
    SELECT results_ne( $1, $2, NULL::text );
$$ LANGUAGE sql;

-- isa_ok( value, regtype, description )
CREATE OR REPLACE FUNCTION isa_ok( anyelement, regtype, TEXT )
RETURNS TEXT AS $$
DECLARE
    typeof regtype := pg_typeof($1);
BEGIN
    IF typeof = $2 THEN RETURN ok(true, $3 || ' isa ' || $2 ); END IF;
    RETURN ok(false, $3 || ' isa ' || $2 ) || E'\n' ||
        diag('    ' || $3 || ' isn''t a "' || $2 || '" it''s a "' || typeof || '"');
END;
$$ LANGUAGE plpgsql;

-- isa_ok( value, regtype )
CREATE OR REPLACE FUNCTION isa_ok( anyelement, regtype )
RETURNS TEXT AS $$
    SELECT isa_ok($1, $2, 'the value');
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION _is_trusted( NAME )
RETURNS BOOLEAN AS $$
    SELECT lanpltrusted FROM pg_catalog.pg_language WHERE lanname = $1;
$$ LANGUAGE SQL;

-- language_is_trusted( language, description )
CREATE OR REPLACE FUNCTION language_is_trusted( NAME, TEXT )
RETURNS TEXT AS $$
DECLARE
    is_trusted boolean := _is_trusted($1);
BEGIN
    IF is_trusted IS NULL THEN
        RETURN fail( $2 ) || E'\n' || diag( '    Procedural language ' || quote_ident($1) || ' does not exist') ;
    END IF;
    RETURN ok( is_trusted, $2 );
END;
$$ LANGUAGE plpgsql;

