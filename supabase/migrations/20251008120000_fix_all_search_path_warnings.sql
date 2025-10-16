/*
# [BATCH] Fix Function Search Path
Corrige o aviso de segurança "Function Search Path Mutable" para um conjunto de funções do banco de dados, definindo um `search_path` explícito e seguro para cada uma.

## Query Description: Esta operação altera a configuração de múltiplas funções para aprimorar a segurança, sem alterar a lógica de negócio ou os dados. A operação é segura e não deve impactar a funcionalidade existente. Cada alteração é envolvida em um bloco que ignora o erro caso a função não exista, garantindo que o script possa ser executado sem falhas em diferentes estados do schema.

## Metadata:
- Schema-Category: ["Security", "Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: false
- Reversible: true

## Structure Details:
- Altera a configuração `search_path` das seguintes funções (se existirem):
  - create_empresa_and_link_owner_client
  - delete_empresa_if_member
  - create_cliente_fornecedor_completo
  - update_cliente_fornecedor_completo
  - delete_cliente_fornecedor_if_member
  - create_cliente_anexo
  - create_produto_completo
  - update_produto_completo
  - delete_produto
  - create_produto_imagem
  - create_embalagem
  - update_embalagem
  - delete_embalagem
  - create_servico
  - update_servico
  - delete_servico
  - set_papel_permissions
  - check_cpf_exists
  - check_cnpj_exists
  - is_member_of

## Security Implications:
- RLS Status: Inalterado
- Policy Changes: Não
- Auth Requirements: `postgres` (admin)
- Description: Mitiga o risco de ataques de sequestro de `search_path` (path hijacking), garantindo que as funções procurem objetos apenas nos schemas especificados (neste caso, `public`).

## Performance Impact:
- Indexes: Nenhum
- Triggers: Nenhum
- Estimated Impact: Nenhum impacto de performance esperado. A alteração é apenas em metadados da função.
*/

DO $$
BEGIN
    ALTER FUNCTION public.create_empresa_and_link_owner_client(p_razao_social text, p_fantasia text, p_cnpj text) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função create_empresa_and_link_owner_client não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.delete_empresa_if_member(p_empresa_id uuid) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função delete_empresa_if_member não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.create_cliente_fornecedor_completo(p_empresa_id uuid, p_cliente_data jsonb, p_contatos jsonb) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função create_cliente_fornecedor_completo não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função update_cliente_fornecedor_completo não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.delete_cliente_fornecedor_if_member(p_id uuid) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função delete_cliente_fornecedor_if_member não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes integer) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função create_cliente_anexo não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.create_produto_completo(p_empresa_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função create_produto_completo não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função update_produto_completo não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.delete_produto(p_id uuid) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função delete_produto não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes integer) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função create_produto_imagem não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.create_embalagem(p_empresa_id uuid, p_descricao text, p_tipo text, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função create_embalagem não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.update_embalagem(p_id uuid, p_descricao text, p_tipo text, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função update_embalagem não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.delete_embalagem(p_id uuid) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função delete_embalagem não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.create_servico(p_empresa_id uuid, p_descricao text, p_preco numeric, p_situacao text) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função create_servico não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.update_servico(p_id uuid, p_descricao text, p_preco numeric, p_situacao text) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função update_servico não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.delete_servico(p_id uuid) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função delete_servico não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.set_papel_permissions(p_papel_id uuid, p_permission_ids text[]) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função set_papel_permissions não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.check_cpf_exists(p_empresa_id uuid, p_cpf text) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função check_cpf_exists não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.check_cnpj_exists(p_empresa_id uuid, p_cnpj text) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função check_cnpj_exists não encontrada, pulando.';
END;
$$;

DO $$
BEGIN
    ALTER FUNCTION public.is_member_of(uuid) SET search_path = public;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Função is_member_of não encontrada, pulando.';
END;
$$;
