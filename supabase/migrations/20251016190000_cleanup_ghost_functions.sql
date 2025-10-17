-- Passo 1: Cria funções "fantasma" para garantir que elas possam ser excluídas.
CREATE OR REPLACE FUNCTION public.apply_rls_policy()
RETURNS void AS $$ BEGIN END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.apply_permissive_rls_to_all_tables()
RETURNS void AS $$ BEGIN END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.apply_rls_policies_to_all_tables()
RETURNS void AS $$ BEGIN END; $$ LANGUAGE plpgsql;

-- Passo 2: Exclui as funções "fantasma" agora que temos certeza que elas existem.
DROP FUNCTION IF EXISTS public.apply_rls_policy();
DROP FUNCTION IF EXISTS public.apply_permissive_rls_to_all_tables();
DROP FUNCTION IF EXISTS public.apply_rls_policies_to_all_tables();

-- Passo 3: Corrige a função de segurança essencial que ainda causa um warning.
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
    -- Verifica se o usuário autenticado (auth.uid()) pertence à empresa especificada.
    RETURN EXISTS (
        SELECT 1
        FROM public.empresa_usuarios
        WHERE empresa_id = p_empresa_id
          AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Aplica a configuração de segurança na função para resolver o warning.
ALTER FUNCTION private.is_member_of_empresa(uuid) SET search_path = public;
