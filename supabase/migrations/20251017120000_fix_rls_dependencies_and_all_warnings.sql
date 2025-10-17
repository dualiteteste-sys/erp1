-- Remove a função e todas as políticas de segurança que dependem dela.
DROP FUNCTION IF EXISTS public.is_member_of_empresa(uuid) CASCADE;

-- Recria a função com o search_path seguro.
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Verifica se o usuário autenticado pertence à empresa_usuarios para a empresa especificada.
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios eu
    WHERE eu.empresa_id = p_empresa_id
      AND eu.user_id = auth.uid()
  );
END;
$$;

-- Recria as políticas de segurança para cada tabela que foi afetada.

-- Tabela: clientes_fornecedores
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company clients"
ON public.clientes_fornecedores FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: clientes_contatos
ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their company contacts"
ON public.clientes_contatos FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: clientes_anexos
ALTER TABLE public.clientes_anexos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their company attachments"
ON public.clientes_anexos FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: produtos
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company products"
ON public.produtos FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: produto_imagens
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage product images"
ON public.produto_imagens FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM produtos p
    WHERE p.id = produto_imagens.produto_id AND is_member_of_empresa(p.empresa_id)
  )
);

-- Tabela: servicos
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company servicos"
ON public.servicos FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: vendedores
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Vendedores members can do all actions"
ON public.vendedores FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: vendedores_contatos
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Vendedores contatos members can do all actions"
ON public.vendedores_contatos FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: embalagens
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Embalagens members can do all actions"
ON public.embalagens FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: crm_oportunidades
ALTER TABLE public.crm_oportunidades ENABLE ROW LEVEL SECURITY;
CREATE POLICY "CRM Oportunidades members can do all actions"
ON public.crm_oportunidades FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: crm_oportunidade_itens
ALTER TABLE public.crm_oportunidade_itens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "CRM Oportunidade Itens members can do all actions"
ON public.crm_oportunidade_itens FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM crm_oportunidades o
    WHERE o.id = crm_oportunidade_itens.oportunidade_id AND is_member_of_empresa(o.empresa_id)
  )
);

-- Tabela: pedidos_vendas
ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permite acesso total para membros da empresa"
ON public.pedidos_vendas FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- Tabela: pedidos_vendas_itens
ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permite acesso total para membros da empresa"
ON public.pedidos_vendas_itens FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM pedidos_vendas pv
    WHERE pv.id = pedidos_vendas_itens.pedido_venda_id AND is_member_of_empresa(pv.empresa_id)
  )
);

-- Corrige as outras funções que também estavam causando avisos.
DROP FUNCTION IF EXISTS private.get_empresa_id_for_user(uuid) CASCADE;
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = p_user_id LIMIT 1;
$$;

DROP FUNCTION IF EXISTS public.create_cliente_anexo(uuid,uuid,text,text,text,bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS TABLE(id uuid, created_at timestamptz, empresa_id uuid, cliente_fornecedor_id uuid, storage_path text, filename text, content_type text, tamanho_bytes bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não autorizado para esta empresa.';
    END IF;

    RETURN QUERY
    INSERT INTO public.clientes_anexos (empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
    VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING *;
END;
$$;
