-- Remove e recria a função `is_member_of_empresa` para quebrar dependências
DROP FUNCTION IF EXISTS public.is_member_of_empresa(uuid) CASCADE;
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = "$user", public, extensions
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios eu
    WHERE eu.empresa_id = p_empresa_id
      AND eu.user_id = auth.uid()
  );
END;
$$;

-- Remove e recria `get_empresa_id_for_user`
DROP FUNCTION IF EXISTS public.get_empresa_id_for_user(uuid);
CREATE OR REPLACE FUNCTION public.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = "$user", public, extensions
AS $$
BEGIN
  RETURN (
    SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = p_user_id LIMIT 1
  );
END;
$$;

-- Remove e recria `handle_new_user`
DROP FUNCTION IF EXISTS public.handle_new_user();
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = "$user", public, extensions
AS $$
BEGIN
  INSERT INTO public.perfis (id, nome_completo, cpf)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'fullName',
    NEW.raw_user_meta_data->>'cpf_cnpj'
  );
  RETURN NEW;
END;
$$;

-- Recria todas as políticas de RLS que foram removidas pelo CASCADE
-- Servicos
ALTER TABLE public.servicos DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow members to manage their own company servicos" ON public.servicos;
CREATE POLICY "Allow members to manage their own company servicos" ON public.servicos
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;

-- Vendedores
ALTER TABLE public.vendedores DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendedores members can do all actions" ON public.vendedores;
CREATE POLICY "Vendedores members can do all actions" ON public.vendedores
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;

-- Vendedores Contatos
ALTER TABLE public.vendedores_contatos DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendedores contatos members can do all actions" ON public.vendedores_contatos;
CREATE POLICY "Vendedores contatos members can do all actions" ON public.vendedores_contatos
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;

-- Embalagens
ALTER TABLE public.embalagens DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Embalagens members can do all actions" ON public.embalagens;
CREATE POLICY "Embalagens members can do all actions" ON public.embalagens
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;

-- CRM Oportunidades
ALTER TABLE public.crm_oportunidades DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "CRM Oportunidades members can do all actions" ON public.crm_oportunidades;
CREATE POLICY "CRM Oportunidades members can do all actions" ON public.crm_oportunidades
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.crm_oportunidades ENABLE ROW LEVEL SECURITY;

-- Pedidos de Venda
ALTER TABLE public.pedidos_vendas DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.pedidos_vendas;
CREATE POLICY "Permite acesso total para membros da empresa" ON public.pedidos_vendas
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;

-- Pedidos de Venda Itens
ALTER TABLE public.pedidos_vendas_itens DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.pedidos_vendas_itens;
CREATE POLICY "Permite acesso total para membros da empresa" ON public.pedidos_vendas_itens
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;

-- Produtos
ALTER TABLE public.produtos DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.produtos;
CREATE POLICY "Permite acesso total para membros da empresa" ON public.produtos
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- Clientes Fornecedores
ALTER TABLE public.clientes_fornecedores DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.clientes_fornecedores;
CREATE POLICY "Permite acesso total para membros da empresa" ON public.clientes_fornecedores
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;

-- Papeis
ALTER TABLE public.papeis DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.papeis;
CREATE POLICY "Permite acesso total para membros da empresa" ON public.papeis
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;

-- Categorias Financeiras
ALTER TABLE public.categorias_financeiras DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.categorias_financeiras;
CREATE POLICY "Permite acesso total para membros da empresa" ON public.categorias_financeiras
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;

-- Formas de Pagamento
ALTER TABLE public.formas_pagamento DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.formas_pagamento;
CREATE POLICY "Permite acesso total para membros da empresa" ON public.formas_pagamento
  FOR ALL USING (public.is_member_of_empresa(empresa_id));
ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;

-- Altera as funções restantes para definir o search_path
ALTER FUNCTION public.check_cnpj_exists(p_empresa_id uuid, p_cnpj text) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.check_cpf_exists(p_empresa_id uuid, p_cpf text) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.check_vendedor_email_exists(p_empresa_id uuid, p_email text, p_vendedor_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_cliente_fornecedor_completo(p_empresa_id uuid, p_cliente_data jsonb, p_contatos jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_crm_oportunidade(p_empresa_id uuid, p_oportunidade_data jsonb, p_itens jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_embalagem(p_empresa_id uuid, p_descricao text, p_tipo text, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_empresa_and_link_owner_client(p_razao_social text, p_fantasia text, p_cnpj text) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_pedido_venda_completo(p_empresa_id uuid, p_pedido_data jsonb, p_itens jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_produto_completo(p_empresa_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_servico(p_empresa_id uuid, p_descricao text, p_preco numeric, p_situacao text, p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.create_vendedor(p_empresa_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa text, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms text, p_inscricao_estadual text, p_situacao text, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato jsonb, p_permissoes_modulos jsonb, p_regra_liberacao_comissao text, p_tipo_comissao text, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.delete_cliente_fornecedor_if_member(p_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.delete_crm_oportunidade(p_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.delete_embalagem(p_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.delete_empresa_if_member(p_empresa_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.delete_pedido_venda(p_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.delete_produto(p_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.delete_servico(p_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.delete_vendedor(p_id uuid) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.search_produtos_e_servicos(p_empresa_id uuid, p_query text) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.set_papel_permissions(p_papel_id uuid, p_permission_ids text[]) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.update_crm_oportunidade(p_oportunidade_id uuid, p_oportunidade_data jsonb, p_itens jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.update_embalagem(p_id uuid, p_descricao text, p_tipo text, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.update_pedido_venda_completo(p_pedido_id uuid, p_pedido_data jsonb, p_itens jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.update_servico(p_id uuid, p_descricao text, p_preco numeric, p_situacao text, p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text) SET search_path = "$user", public, extensions;
ALTER FUNCTION public.update_vendedor(p_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa text, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms text, p_inscricao_estadual text, p_situacao text, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato jsonb, p_permissoes_modulos jsonb, p_regra_liberacao_comissao text, p_tipo_comissao text, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb) SET search_path = "$user", public, extensions;
