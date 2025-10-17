DO $$
DECLARE
    func_signature TEXT;
BEGIN
    RAISE NOTICE 'Iniciando a correção dos avisos de segurança "Function Search Path Mutable"...';

    -- Itera sobre todas as funções criadas pelo usuário no schema 'public'
    FOR func_signature IN
        SELECT
            -- Formato: public.nome_da_funcao(text, uuid, etc)
            ns.nspname || '.' || p.proname || '(' || pg_catalog.pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_catalog.pg_proc p
            JOIN pg_catalog.pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Apenas funções no schema public
            AND p.prokind = 'f'    -- Apenas funções normais (exclui procedures, aggregates, etc.)
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres') -- Exclui funções do próprio Supabase/Postgres
    LOOP
        RAISE NOTICE 'Aplicando correção em: %', func_signature;
        -- Aplica a configuração de segurança em cada função encontrada
        EXECUTE 'ALTER FUNCTION ' || func_signature || ' SET search_path = ''public'';';
    END LOOP;

    -- Corrige manualmente a função no schema 'private'
    RAISE NOTICE 'Aplicando correção em: private.get_empresa_id_for_user(uuid)';
    EXECUTE 'ALTER FUNCTION private.get_empresa_id_for_user(uuid) SET search_path = ''public'';';

    RAISE NOTICE 'Correção de segurança concluída com sucesso!';
END;
$$ LANGUAGE plpgsql;
