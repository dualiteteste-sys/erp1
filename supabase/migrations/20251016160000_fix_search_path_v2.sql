/*
# [SECURITY] Fix Function Search Path (v2)
Corrige a consulta para ser compatível com versões mais recentes do PostgreSQL e define um `search_path` seguro para todas as funções do usuário no schema `public`. Isso resolve os avisos de segurança "Function Search Path Mutable".

## Query Description:
Esta operação é segura e não afeta os dados. Ela modifica os metadados de todas as funções criadas por você para melhorar a segurança, prevenindo uma classe de vulnerabilidades conhecida como "search path hijacking". Não há risco de perda de dados.

## Metadata:
- Schema-Category: ["Security", "Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: false
- Reversible: true (manualmente, removendo o SET search_path de cada função)

## Structure Details:
- Afeta: Funções no schema `public`.
- Ação: `ALTER FUNCTION ... SET search_path`

## Security Implications:
- RLS Status: Não afetado.
- Policy Changes: Não.
- Auth Requirements: N/A.
- Efeito: Mitiga a vulnerabilidade "Function Search Path Mutable".

## Performance Impact:
- Indexes: Nenhum.
- Triggers: Nenhum.
- Estimated Impact: Nenhum impacto perceptível na performance.
*/

DO $$
DECLARE
    function_signature TEXT;
BEGIN
    FOR function_signature IN
        SELECT
            -- Formato: schema_name.function_name(arg_types)
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Apenas funções no schema public
            AND p.prokind = 'f' -- 'f' para funções normais (exclui procedures, aggregates, etc.)
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres', 'supabase_auth_admin') -- Exclui funções do sistema/extensões
    LOOP
        -- Define um search_path seguro para cada função
        EXECUTE 'ALTER FUNCTION ' || function_signature || ' SET search_path = "$user", public, extensions;';
    END LOOP;
END;
$$;
