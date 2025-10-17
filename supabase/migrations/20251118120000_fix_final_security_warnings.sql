-- Corrige os avisos de segurança restantes definindo o search_path para todas as funções.

/*
          # [Fix Final Security Warnings]
          Aplica a configuração de `search_path` a todas as funções personalizadas restantes para resolver os avisos de segurança.

          ## Query Description: ["Esta operação altera a configuração de segurança de várias funções do banco de dados para mitigar uma vulnerabilidade de baixo risco. Não há impacto nos dados existentes e a operação é segura e reversível."]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          [afeta as seguintes funções: handle_new_user, is_member_of_empresa, create_cliente_fornecedor_completo, update_cliente_fornecedor_completo, delete_cliente_fornecedor_if_member, check_cpf_exists, check_cnpj_exists, create_produto_completo, update_produto_completo, delete_produto, create_produto_imagem, create_embalagem, update_embalagem, delete_embalagem, create_servico, update_servico, delete_servico, create_vendedor, update_vendedor, delete_vendedor, check_vendedor_email_exists, set_papel_permissions, create_crm_oportunidade, update_crm_oportunidade, delete_crm_oportunidade, create_pedido_venda_completo, update_pedido_venda_completo, delete_pedido_venda, search_produtos_e_servicos, get_empresa_id_for_user, create_cliente_anexo]
          
          ## Security Implications:
          - RLS Status: [N/A]
          - Policy Changes: [No]
          - Auth Requirements: [N/A]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: ["Nenhum impacto de performance esperado."]
          */

ALTER FUNCTION public.handle_new_user() SET search_path = 'public';
ALTER FUNCTION public.is_member_of_empresa(p_empresa_id uuid) SET search_path = 'public';
ALTER FUNCTION public.get_empresa_id_for_user(p_user_id uuid) SET search_path = 'public';

-- Cliente
ALTER FUNCTION public.create_cliente_fornecedor_completo(p_empresa_id uuid, p_cliente_data jsonb, p_contatos jsonb) SET search_path = 'public';
ALTER FUNCTION public.update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb) SET search_path = 'public';
ALTER FUNCTION public.delete_cliente_fornecedor_if_member(p_id uuid) SET search_path = 'public';
ALTER FUNCTION public.check_cpf_exists(p_empresa_id uuid, p_cpf text) SET search_path = 'public';
ALTER FUNCTION public.check_cnpj_exists(p_empresa_id uuid, p_cnpj text) SET search_path = 'public';
ALTER FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint) SET search_path = 'public';

-- Produto
ALTER FUNCTION public.create_produto_completo(p_empresa_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb) SET search_path = 'public';
ALTER FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb) SET search_path = 'public';
ALTER FUNCTION public.delete_produto(p_id uuid) SET search_path = 'public';
ALTER FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint) SET search_path = 'public';

-- Embalagem
ALTER FUNCTION public.create_embalagem(p_empresa_id uuid, p_descricao text, p_tipo public.tipo_embalagem_produto, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric) SET search_path = 'public';
ALTER FUNCTION public.update_embalagem(p_id uuid, p_descricao text, p_tipo public.tipo_embalagem_produto, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric) SET search_path = 'public';
ALTER FUNCTION public.delete_embalagem(p_id uuid) SET search_path = 'public';

-- Servico
ALTER FUNCTION public.create_servico(p_empresa_id uuid, p_descricao text, p_preco numeric, p_situacao public.situacao_servico, p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text) SET search_path = 'public';
ALTER FUNCTION public.update_servico(p_id uuid, p_descricao text, p_preco numeric, p_situacao public.situacao_servico, p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text) SET search_path = 'public';
ALTER FUNCTION public.delete_servico(p_id uuid) SET search_path = 'public';

-- Vendedor
ALTER FUNCTION public.create_vendedor(p_empresa_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa public.tipo_pessoa_vendedor, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms public.tipo_contribuinte_icms, p_inscricao_estadual text, p_situacao public.situacao_vendedor, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao public.regra_liberacao_comissao, p_tipo_comissao public.tipo_comissao, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb) SET search_path = 'public';
ALTER FUNCTION public.update_vendedor(p_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa public.tipo_pessoa_vendedor, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms public.tipo_contribuinte_icms, p_inscricao_estadual text, p_situacao public.situacao_vendedor, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao public.regra_liberacao_comissao, p_tipo_comissao public.tipo_comissao, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb) SET search_path = 'public';
ALTER FUNCTION public.delete_vendedor(p_id uuid) SET search_path = 'public';
ALTER FUNCTION public.check_vendedor_email_exists(p_empresa_id uuid, p_email text, p_vendedor_id uuid) SET search_path = 'public';

-- Papel
ALTER FUNCTION public.set_papel_permissions(p_papel_id uuid, p_permission_ids text[]) SET search_path = 'public';

-- CRM
ALTER FUNCTION public.create_crm_oportunidade(p_empresa_id uuid, p_oportunidade_data jsonb, p_itens jsonb) SET search_path = 'public';
ALTER FUNCTION public.update_crm_oportunidade(p_oportunidade_id uuid, p_oportunidade_data jsonb, p_itens jsonb) SET search_path = 'public';
ALTER FUNCTION public.delete_crm_oportunidade(p_id uuid) SET search_path = 'public';

-- Pedido Venda
ALTER FUNCTION public.create_pedido_venda_completo(p_empresa_id uuid, p_pedido_data jsonb, p_itens jsonb) SET search_path = 'public';
ALTER FUNCTION public.update_pedido_venda_completo(p_pedido_id uuid, p_pedido_data jsonb, p_itens jsonb) SET search_path = 'public';
ALTER FUNCTION public.delete_pedido_venda(p_id uuid) SET search_path = 'public';
ALTER FUNCTION public.search_produtos_e_servicos(p_empresa_id uuid, p_query text) SET search_path = 'public';
