DO $$
DECLARE
    function_signature TEXT;
BEGIN
    -- Itera sobre todas as funções no esquema 'public' que não são do sistema
    FOR function_signature IN
        SELECT
            -- Formata a assinatura completa da função, ex: public.my_function(uuid, text)
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Apenas funções no esquema public
            AND p.prokind = 'f' -- 'f' para funções normais (exclui procedures, aggregates)
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres') -- Exclui funções do sistema/proprietário
    LOOP
        -- Aplica a configuração de segurança para cada função encontrada
        EXECUTE 'ALTER FUNCTION ' || function_signature || ' SET search_path = "$user", public, extensions;';
    END LOOP;
END $$;
