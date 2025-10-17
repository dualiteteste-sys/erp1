DO $$
DECLARE
    function_signature TEXT;
BEGIN
    -- Loop através de todas as funções no esquema 'public' que não são do sistema
    FOR function_signature IN
        SELECT
            -- Formato é: schema_name.function_name(arg_types)
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Apenas funções no esquema public
            AND p.prokind = 'f' -- 'f' para funções normais
            AND NOT EXISTS (SELECT 1 FROM pg_aggregate WHERE aggfnoid = p.oid) -- Exclui funções de agregação
            AND p.proname NOT LIKE 'pg_%' -- Exclui funções internas do pg
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres') -- Exclui funções do sistema Supabase
    LOOP
        -- Define o search_path para a função atual
        EXECUTE 'ALTER FUNCTION ' || function_signature || ' SET search_path = public, extensions;';
        RAISE NOTICE 'Set search_path for function: %', function_signature;
    END LOOP;
END;
$$;
