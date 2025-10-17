-- Corrige o último warning de search_path
ALTER FUNCTION private.is_member_of_empresa(p_empresa_id uuid) SET search_path = public;

-- Aplica as políticas de RLS em todas as tabelas para garantir a segurança multi-empresa

-- Tabela: clientes_fornecedores
CREATE POLICY "Allow members to manage their own company data"
ON public.clientes_fornecedores FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: clientes_contatos
CREATE POLICY "Allow members to manage their own company data"
ON public.clientes_contatos FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: clientes_anexos
CREATE POLICY "Allow members to manage their own company data"
ON public.clientes_anexos FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: produtos
CREATE POLICY "Allow members to manage their own company data"
ON public.produtos FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: produto_imagens
CREATE POLICY "Allow members to manage their own company data"
ON public.produto_imagens FOR ALL
USING (EXISTS (
  SELECT 1 FROM produtos p WHERE p.id = produto_imagens.produto_id AND private.is_member_of_empresa(p.empresa_id)
));

-- Tabela: produto_atributos
CREATE POLICY "Allow members to manage their own company data"
ON public.produto_atributos FOR ALL
USING (EXISTS (
  SELECT 1 FROM produtos p WHERE p.id = produto_atributos.produto_id AND private.is_member_of_empresa(p.empresa_id)
));

-- Tabela: produto_fornecedores
CREATE POLICY "Allow members to manage their own company data"
ON public.produto_fornecedores FOR ALL
USING (EXISTS (
  SELECT 1 FROM produtos p WHERE p.id = produto_fornecedores.produto_id AND private.is_member_of_empresa(p.empresa_id)
));

-- Tabela: embalagens
CREATE POLICY "Allow members to manage their own company data"
ON public.embalagens FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: servicos
CREATE POLICY "Allow members to manage their own company data"
ON public.servicos FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: vendedores
CREATE POLICY "Allow members to manage their own company data"
ON public.vendedores FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: vendedores_contatos
CREATE POLICY "Allow members to manage their own company data"
ON public.vendedores_contatos FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: papeis
CREATE POLICY "Allow members to manage their own company data"
ON public.papeis FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: papel_permissoes
CREATE POLICY "Allow members to manage their own company data"
ON public.papel_permissoes FOR ALL
USING (EXISTS (
  SELECT 1 FROM papeis p WHERE p.id = papel_permissoes.papel_id AND private.is_member_of_empresa(p.empresa_id)
));

-- Tabela: categorias_financeiras
CREATE POLICY "Allow members to manage their own company data"
ON public.categorias_financeiras FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: formas_pagamento
CREATE POLICY "Allow members to manage their own company data"
ON public.formas_pagamento FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: crm_oportunidades
CREATE POLICY "Allow members to manage their own company data"
ON public.crm_oportunidades FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: crm_oportunidade_itens
CREATE POLICY "Allow members to manage their own company data"
ON public.crm_oportunidade_itens FOR ALL
USING (EXISTS (
  SELECT 1 FROM crm_oportunidades o WHERE o.id = crm_oportunidade_itens.oportunidade_id AND private.is_member_of_empresa(o.empresa_id)
));

-- Tabela: pedidos_vendas
CREATE POLICY "Allow members to manage their own company data"
ON public.pedidos_vendas FOR ALL
USING (private.is_member_of_empresa(empresa_id));

-- Tabela: pedidos_vendas_itens
CREATE POLICY "Allow members to manage their own company data"
ON public.pedidos_vendas_itens FOR ALL
USING (EXISTS (
  SELECT 1 FROM pedidos_vendas pv WHERE pv.id = pedidos_vendas_itens.pedido_venda_id AND private.is_member_of_empresa(pv.empresa_id)
));
