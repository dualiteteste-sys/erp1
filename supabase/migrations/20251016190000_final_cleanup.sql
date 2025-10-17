-- Remove as funções auxiliares antigas que estão causando conflitos.
-- Usamos "IF EXISTS" para evitar erros caso alguma já tenha sido removida.
DROP FUNCTION IF EXISTS public.apply_rls_policy();
DROP FUNCTION IF EXISTS public.apply_permissive_rls_to_all_tables();
DROP FUNCTION IF EXISTS public.apply_rls_policies_to_all_tables();

-- Corrige o aviso de segurança restante na função essencial de verificação de membro.
-- Isso define um caminho de busca seguro, eliminando a vulnerabilidade.
ALTER FUNCTION private.is_member_of_empresa(p_user_id uuid)
SET search_path = public;
