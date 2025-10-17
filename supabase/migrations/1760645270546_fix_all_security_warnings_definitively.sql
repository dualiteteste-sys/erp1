/*
# [SECURITY] Fix Function Search Path
Corrige a vulnerabilidade "Function Search Path Mutable" aplicando um `search_path` seguro para todas as funções criadas pelo usuário no schema `public`.

## Query Description:
Este script inspeciona todas as funções no schema `public` que não pertencem ao sistema e aplica um `ALTER FUNCTION ... SET search_path`. Isso previne que um usuário mal-intencionado possa executar código arbitrário explorando o caminho de busca de funções. A operação é segura e não afeta os dados.

## Metadata:
- Schema-Category: ["Security", "Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: false
- Reversible: true (removendo o SET search_path)

## Structure Details:
- Altera metadados de múltiplas funções no schema `public`.

## Security Implications:
- RLS Status: N/A
- Policy Changes: No
- Auth Requirements: Requer permissões de `ALTER` em funções.

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Nenhum impacto de performance esperado.
*/
DO $$
DECLARE
    func_def RECORD;
BEGIN
    RAISE NOTICE 'Iniciando a correção do search_path para funções...';
    FOR func_def IN
        SELECT
            p.oid AS func_oid,
            ns.nspname AS schema_name,
            p.proname AS func_name,
            pg_get_function_identity_arguments(p.oid) AS func_args
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public'
            AND p.prokind = 'f'
            AND NOT EXISTS (SELECT 1 FROM pg_aggregate WHERE aggfnoid = p.oid)
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres')
    LOOP
        RAISE NOTICE 'Aplicando correção em: %.%(%)', func_def.schema_name, func_def.func_name, func_def.func_args;
        EXECUTE format('ALTER FUNCTION %I.%I(%s) SET search_path = public, extensions;',
                       func_def.schema_name,
                       func_def.func_name,
                       func_def.func_args);
    END LOOP;
    RAISE NOTICE 'Correção do search_path concluída.';
END;
$$;
