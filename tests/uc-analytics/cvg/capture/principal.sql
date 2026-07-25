DO $provision$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_roles
        WHERE rolname = 'capture_reader'
    ) THEN
        CREATE ROLE capture_reader
            LOGIN
            REPLICATION
            PASSWORD 'capture_reader';
    END IF;
END
$provision$;

ALTER ROLE capture_reader WITH
    LOGIN
    REPLICATION
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOINHERIT
    NOBYPASSRLS
    PASSWORD 'capture_reader';

GRANT CONNECT ON DATABASE ecommerce TO capture_reader;
GRANT USAGE ON SCHEMA public TO capture_reader;
GRANT SELECT ON TABLE public.orders TO capture_reader;

REVOKE ALL PRIVILEGES ON SCHEMA _control FROM capture_reader;
