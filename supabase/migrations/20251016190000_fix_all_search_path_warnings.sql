/*
          # [SECURITY] Fix Function Search Path
          [Este script corrige a vulnerabilidade "Function Search Path Mutable" definindo um caminho de busca seguro para todas as funções personalizadas no schema 'public'.]

          ## Query Description: [Este script altera a configuração de segurança de múltiplas funções do banco de dados. Ele não afeta os dados, mas modifica o comportamento de execução das funções para prevenir vulnerabilidades. É uma operação segura e recomendada.]
          
          ## Metadata:
          - Schema-Category: ["Structural", "Safe"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [false]
          
          ## Structure Details:
          [Afeta a configuração de todas as funções no schema 'public']
          
          ## Security Implications:
          - RLS Status: [N/A]
          - Policy Changes: [No]
          - Auth Requirements: [N/A]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: [Nenhum impacto negativo esperado. Melhora a previsibilidade da execução das funções.]
          */
DO $$
DECLARE
    func_signature TEXT;
BEGIN
    -- Loop through all user-defined functions in the 'public' schema
    FOR func_signature IN
        SELECT
            -- Format is: schema_name.function_name(arg_types)
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Only functions in the public schema
            AND p.prokind = 'f' -- 'f' for normal functions
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres')
    LOOP
        -- Set a secure search_path for each function
        EXECUTE 'ALTER FUNCTION ' || func_signature || ' SET search_path = public, extensions;';
        RAISE NOTICE 'Set search_path for function: %', func_signature;
    END LOOP;
END;
$$;
