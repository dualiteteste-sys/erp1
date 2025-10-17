DO $$
DECLARE
    function_signature TEXT;
BEGIN
    RAISE NOTICE 'Iniciando a correção do search_path para todas as funções personalizadas...';

    FOR function_signature IN
        SELECT
            -- Formato: schema_name.function_name(arg_types)
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname IN ('public', 'private') -- Verifica os schemas 'public' e 'private'
            AND p.prokind = 'f' -- 'f' para funções normais (exclui procedures, aggregates, etc.)
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres', 'supabase_auth_admin') -- Exclui funções do sistema
    LOOP
        BEGIN
            RAISE NOTICE 'Aplicando em: %', function_signature;
            EXECUTE 'ALTER FUNCTION ' || function_signature || ' SET search_path = "$user", public, extensions;';
        EXCEPTION
            WHEN others THEN
                RAISE WARNING 'Falha ao alterar a função %. Erro: %', function_signature, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE 'Correção do search_path concluída.';
END;
$$;
