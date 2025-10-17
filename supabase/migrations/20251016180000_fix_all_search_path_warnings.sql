DO $$
DECLARE
    func_signature TEXT;
BEGIN
    FOR func_signature IN
        SELECT format('%I.%I(%s)', ns.nspname, p.proname, pg_get_function_identity_arguments(p.oid))
        FROM pg_proc p
        JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE ns.nspname = 'public' -- Apenas funções no schema public
          AND p.prokind = 'f' -- Apenas funções normais (exclui procedures, aggregates, etc.)
          AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres', 'supabase_auth_admin') -- Exclui funções do sistema Supabase
    LOOP
        -- Define um search_path seguro para cada função encontrada
        EXECUTE format('ALTER FUNCTION %s SET search_path = "$user", public, extensions;', func_signature);
    END LOOP;
END;
$$;
