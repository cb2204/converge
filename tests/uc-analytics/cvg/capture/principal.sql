-- Dedicated read-only capture principal (ADR-0003). Runs against the
-- operational Postgres so the capture read is never attributed to the
-- application connection. REPLICATION lets it create/consume a logical
-- replication slot; SELECT lets it read the tables it captures.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'capture_reader') THEN
        CREATE ROLE capture_reader LOGIN REPLICATION;
    END IF;
END
$$;

GRANT CONNECT ON DATABASE ecommerce TO capture_reader;
GRANT USAGE ON SCHEMA public TO capture_reader;
GRANT SELECT ON public.orders TO capture_reader;

-- No grant of any kind is issued on the _control schema — the fence (ADR-0001)
-- holds by omission, not by a revoked default.
