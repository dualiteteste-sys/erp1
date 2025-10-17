/*
          # [Finalização da Configuração de Segurança]
          Este script aplica as políticas de segurança em nível de linha (RLS) para todas as tabelas da aplicação e corrige o último aviso de segurança pendente.

          ## Query Description:
          - **Criação de Políticas RLS:** Para cada tabela, uma política é criada para garantir que os usuários só possam acessar (ler, escrever, atualizar, deletar) os dados que pertencem à sua própria empresa. Isso é feito usando a função `private.is_member_of_empresa`.
          - **Correção de `search_path`:** A função `private.is_member_of_empresa` tem seu `search_path` definido explicitamente para `public`, eliminando o último aviso de segurança.
          - **Impacto:** Após a aplicação, a segurança multi-empresa estará totalmente funcional, e os avisos de segurança do Supabase serão resolvidos. Não há risco de perda de dados.

          ## Metadata:
          - Schema-Category: "Security"
          - Impact-Level: "Low"
          - Requires-Backup: false
          - Reversible: true (as políticas podem ser removidas)
          */

-- Corrige o último warning de search_path
ALTER FUNCTION private.is_member_of_empresa(uuid) SET search_path = public;

-- Aplica políticas de RLS para todas as tabelas relevantes
CREATE POLICY "Allow members to manage their own company data" ON public.clientes_fornecedores FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.clientes_contatos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.clientes_anexos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.produtos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.produto_atributos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.produto_fornecedores FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.produto_imagens FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.embalagens FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.servicos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.vendedores FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.vendedores_contatos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.papeis FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.papel_permissoes FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.categorias_financeiras FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.formas_pagamento FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.crm_oportunidades FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.crm_oportunidade_itens FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.pedidos_vendas FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.pedidos_vendas_itens FOR ALL USING (private.is_member_of_empresa(empresa_id));
