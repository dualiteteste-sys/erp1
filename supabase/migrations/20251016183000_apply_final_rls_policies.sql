-- Habilita a extensão pgcrypto se ainda não estiver habilitada
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Cria a função de verificação de membro da empresa no esquema 'private' para segurança.
-- Esta função é a base para todas as políticas de RLS.
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM empresa_usuarios
    WHERE user_id = p_user_id AND empresa_id = p_empresa_id
  );
END;
$$;

-- Aplica as políticas de segurança (RLS) em todas as tabelas relevantes.
-- Isso garante que os usuários só possam acessar os dados da empresa à qual pertencem.

-- Tabela: empresas
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Membros podem ver suas próprias empresas" ON public.empresas;
CREATE POLICY "Membros podem ver suas próprias empresas" ON public.empresas
FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.empresa_usuarios eu
    WHERE eu.empresa_id = empresas.id AND eu.user_id = auth.uid()
));

-- Tabela: empresa_usuarios
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Usuários podem ver seus próprios vínculos" ON public.empresa_usuarios;
CREATE POLICY "Usuários podem ver seus próprios vínculos" ON public.empresa_usuarios
FOR SELECT USING (auth.uid() = user_id);

-- Lista de tabelas que usam a política padrão baseada em 'empresa_id'
DO $$
DECLARE
    v_table_name TEXT;
    v_tables TEXT[] := ARRAY[
        'clientes_fornecedores', 'clientes_contatos', 'clientes_anexos',
        'produtos', 'produto_imagens', 'produto_atributos', 'produto_fornecedores',
        'servicos', 'embalagens', 'vendedores', 'vendedores_contatos',
        'papeis', 'papel_permissoes', 'categorias_financeiras', 'formas_pagamento',
        'crm_oportunidades', 'crm_oportunidade_itens', 'pedidos_vendas', 'pedidos_vendas_itens'
    ];
BEGIN
    FOREACH v_table_name IN ARRAY v_tables
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', v_table_name);
        
        EXECUTE format('DROP POLICY IF EXISTS "Membros podem gerenciar dados da sua empresa" ON public.%I;', v_table_name);

        EXECUTE format('
            CREATE POLICY "Membros podem gerenciar dados da sua empresa"
            ON public.%I
            FOR ALL
            USING (private.is_member_of_empresa(auth.uid(), empresa_id));
        ', v_table_name);
    END LOOP;
END;
$$;
