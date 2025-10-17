-- Remove as funções de script antigas que não são mais necessárias.
DROP FUNCTION IF EXISTS public.apply_rls_policy();
DROP FUNCTION IF EXISTS public.apply_permissive_rls_to_all_tables();
DROP FUNCTION IF EXISTS public.apply_rls_policies_to_all_tables();

-- Corrige a função de segurança essencial, adicionando o search_path.
ALTER FUNCTION private.is_member_of_empresa(p_empresa_id uuid)
SET search_path = public;
