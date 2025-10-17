-- Recria a estrutura de Papéis e Permissões e corrige avisos de segurança.

-- 1. Remove estruturas antigas ou incompletas, se existirem.
DROP TABLE IF EXISTS public.papel_permissoes;
DROP TABLE IF EXISTS public.papeis;

-- 2. Cria a tabela de Papéis
CREATE TABLE public.papeis (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;

-- 3. Cria a tabela de junção para permissões
CREATE TABLE public.papel_permissoes (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
    permissao_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (papel_id, permissao_id)
);
ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;

-- 4. Adiciona políticas de segurança para as novas tabelas
CREATE POLICY "Allow full access for company members" ON public.papeis
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

CREATE POLICY "Allow full access for company members" ON public.papel_permissoes
FOR ALL
USING (auth.uid() IN (SELECT user_id FROM empresa_usuarios WHERE empresa_id = (SELECT empresa_id FROM papeis WHERE id = papel_id)))
WITH CHECK (auth.uid() IN (SELECT user_id FROM empresa_usuarios WHERE empresa_id = (SELECT empresa_id FROM papeis WHERE id = papel_id)));

-- 5. Corrige os avisos de segurança restantes
DO $$
DECLARE
    function_signature TEXT;
BEGIN
    FOR function_signature IN
        SELECT
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public'
            AND p.prokind = 'f'
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres')
    LOOP
        EXECUTE 'ALTER FUNCTION ' || function_signature || ' SET search_path = public, extensions;';
    END LOOP;
END;
$$;
