DO $$
DECLARE
    func_signature TEXT;
BEGIN
    -- Fix functions in the 'public' schema
    FOR func_signature IN
        SELECT
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public'
            AND p.prokind = 'f'
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres')
    LOOP
        BEGIN
            EXECUTE 'ALTER FUNCTION ' || func_signature || ' SET search_path = public;';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Não foi possível alterar a função %: %', func_signature, SQLERRM;
        END;
    END LOOP;

    -- Fix functions in the 'private' schema
    FOR func_signature IN
        SELECT
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'private'
            AND p.prokind = 'f'
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres')
    LOOP
        BEGIN
            -- Funções privadas podem precisar acessar o schema público também
            EXECUTE 'ALTER FUNCTION ' || func_signature || ' SET search_path = public, private;';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Não foi possível alterar a função %: %', func_signature, SQLERRM;
        END;
    END LOOP;
END;
$$;
