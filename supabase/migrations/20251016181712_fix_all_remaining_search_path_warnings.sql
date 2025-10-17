DO $$
DECLARE
    function_signature TEXT;
BEGIN
    FOR function_signature IN
        SELECT
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Apenas funções no schema público
            AND p.prokind = 'f' -- Apenas funções normais (exclui aggregates, procedures, etc.)
            AND p.proname NOT LIKE 'pg_%' -- Exclui funções internas do Postgres
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres') -- Exclui funções do sistema Supabase
    LOOP
        EXECUTE 'ALTER FUNCTION ' || function_signature || ' SET search_path = ''public'';';
    END LOOP;
END $$;
