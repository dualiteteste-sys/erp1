DO $$
DECLARE
    func_def TEXT;
BEGIN
    FOR func_def IN
        SELECT
            -- Formato: schema_name.function_name(arg_types)
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Apenas funções no schema public
            AND p.prokind = 'f' -- 'f' para funções normais (exclui procedures, aggregates, etc.)
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres') -- Exclui funções do sistema
    LOOP
        -- Define o search_path para a função, garantindo segurança
        EXECUTE 'ALTER FUNCTION ' || func_def || ' SET search_path = public;';
    END LOOP;
END $$;
