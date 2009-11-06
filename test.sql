DROP FUNCTION plparrot_call_handler() CASCADE;
CREATE FUNCTION plparrot_call_handler() RETURNS LANGUAGE_HANDLER AS 'plparrot' LANGUAGE C;
CREATE LANGUAGE plparrot HANDLER plparrot_call_handler;
