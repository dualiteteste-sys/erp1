-- Comprehensive RLS and Policy Reset
-- This script will reset all Row Level Security policies for the main tables
-- to ensure consistency and fix "already exists" errors.

-- Step 1: Drop all existing policies idempotently.
DROP POLICY IF EXISTS "Allow members to manage their own company servicos" ON public.servicos;
DROP POLICY IF EXISTS "Servicos members can do all actions" ON public.servicos;
DROP POLICY IF EXISTS "Vendedores members can do all actions" ON public.vendedores;
DROP POLICY IF EXISTS "Vendedores contatos members can do all actions" ON public.vendedores_contatos;
DROP POLICY IF EXISTS "Embalagens members can do all actions" ON public.embalagens;
DROP POLICY IF EXISTS "CRM Oportunidades members can do all actions" ON public.crm_oportunidades;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.pedidos_vendas;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.pedidos_vendas_itens;
DROP POLICY IF EXISTS "Allow members to manage their own company data" ON public.clientes_fornecedores;
DROP POLICY IF EXISTS "Allow members to manage their own company data" ON public.produtos;
DROP POLICY IF EXISTS "Allow members to manage their own company data" ON public.papeis;
DROP POLICY IF EXISTS "Allow members to manage their own company data" ON public.categorias_financeiras;
DROP POLICY IF EXISTS "Allow members to manage their own company data" ON public.formas_pagamento;
DROP POLICY IF EXISTS "Allow members to manage their own company data" ON public.crm_oportunidade_itens;


-- Step 2: Recreate helper functions with security settings.
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = private
AS $$
  SELECT empresa_id FROM empresa_usuarios WHERE user_id = p_user_id LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private
AS $$
DECLARE
  is_member boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM empresa_usuarios
    WHERE empresa_id = p_empresa_id
      AND user_id = auth.uid()
  ) INTO is_member;
  RETURN is_member;
END;
$$;


-- Step 3: Re-enable RLS and create policies for all tables.

-- Tabela: clientes_fornecedores
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.clientes_fornecedores
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: produtos
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.produtos
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: servicos
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.servicos
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: embalagens
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.embalagens
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: vendedores
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.vendedores
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: vendedores_contatos
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.vendedores_contatos
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: crm_oportunidades
ALTER TABLE public.crm_oportunidades ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.crm_oportunidades
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: crm_oportunidade_itens
ALTER TABLE public.crm_oportunidade_itens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.crm_oportunidade_itens
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: pedidos_vendas
ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.pedidos_vendas
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: pedidos_vendas_itens
ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.pedidos_vendas_itens
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: papeis
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.papeis
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: categorias_financeiras
ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.categorias_financeiras
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: formas_pagamento
ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company data" ON public.formas_pagamento
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));
