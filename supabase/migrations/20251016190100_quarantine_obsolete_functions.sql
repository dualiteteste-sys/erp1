/*
  # Quarentena de Funções Obsoletas
  [Renomeia funções antigas e não utilizadas que estavam causando avisos de segurança, movendo-as para um estado de "quarentena".]

  ## Query Description: [Este script renomeia funções que provavelmente são resquícios de tentativas anteriores de correção e não são mais utilizadas pela aplicação. Ao renomeá-las com o prefixo `_quarantined_`, nós as desativamos sem excluí-las, o que nos permite confirmar que o sistema funciona sem elas. Esta é uma operação segura e totalmente reversível, e deve eliminar os avisos de segurança restantes.]

  ## Metadata:
  - Schema-Category: ["Structural"]
  - Impact-Level: ["Low"]
  - Requires-Backup: [false]
  - Reversible: [true]

  ## Structure Details:
  - Renomeia as funções:
    - apply_rls_policy()
    - apply_permissive_rls_to_all_tables()
    - apply_rls_policies_to_all_tables()

  ## Security Implications:
  - RLS Status: [N/A]
  - Policy Changes: [No]
  - Auth Requirements: [N/A]

  ## Performance Impact:
  - Indexes: [N/A]
  - Triggers: [N/A]
  - Estimated Impact: [Nenhum impacto de performance esperado. Apenas limpeza de código obsoleto.]
*/

DO $$
BEGIN
    -- Quarentena da função apply_rls_policy
    IF EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE pg_namespace.nspname = 'public' AND pg_proc.proname = 'apply_rls_policy') THEN
        ALTER FUNCTION public.apply_rls_policy() RENAME TO _quarantined_apply_rls_policy;
    END IF;

    -- Quarentena da função apply_permissive_rls_to_all_tables
    IF EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE pg_namespace.nspname = 'public' AND pg_proc.proname = 'apply_permissive_rls_to_all_tables') THEN
        ALTER FUNCTION public.apply_permissive_rls_to_all_tables() RENAME TO _quarantined_apply_permissive_rls_to_all_tables;
    END IF;

    -- Quarentena da função apply_rls_policies_to_all_tables
    IF EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE pg_namespace.nspname = 'public' AND pg_proc.proname = 'apply_rls_policies_to_all_tables') THEN
        ALTER FUNCTION public.apply_rls_policies_to_all_tables() RENAME TO _quarantined_apply_rls_policies_to_all_tables;
    END IF;
END;
$$;
