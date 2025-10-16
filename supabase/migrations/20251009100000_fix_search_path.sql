/*
  # [SECURITY] Fix Function Search Path
  [This migration addresses security advisories by explicitly setting the `search_path` for all custom database functions. This prevents potential security vulnerabilities related to search path hijacking.]

  ## Query Description: [This operation updates the configuration of existing database functions to make them more secure. It sets a fixed `search_path`, ensuring that functions execute in a predictable and safe environment. This change has no impact on existing data and is fully reversible.]
  
  ## Metadata:
  - Schema-Category: ["Security", "Structural"]
  - Impact-Level: ["Low"]
  - Requires-Backup: [false]
  - Reversible: [true]
  
  ## Structure Details:
  [This script affects custom database functions by setting their `search_path` to 'public'.]
  
  ## Security Implications:
  - RLS Status: [Not Changed]
  - Policy Changes: [No]
  - Auth Requirements: [None]
  - This migration directly addresses and resolves the "Function Search Path Mutable" security advisory.
  
  ## Performance Impact:
  - Indexes: [Not Changed]
  - Triggers: [Not Changed]
  - Estimated Impact: [None. This is a configuration change with no performance overhead.]
*/

-- Set search_path for all functions to enhance security
ALTER FUNCTION public.is_member_of(uuid) SET search_path = public;
ALTER FUNCTION public.create_cliente_fornecedor_completo(uuid, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION public.update_cliente_fornecedor_completo(uuid, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION public.delete_cliente_fornecedor_if_member(uuid) SET search_path = public;
ALTER FUNCTION public.create_cliente_anexo(uuid, uuid, text, text, text, bigint) SET search_path = public;
ALTER FUNCTION public.create_embalagem(uuid, text, public.tipo_embalagem_produto, numeric, numeric, numeric, numeric, numeric) SET search_path = public;
ALTER FUNCTION public.update_embalagem(uuid, text, public.tipo_embalagem_produto, numeric, numeric, numeric, numeric, numeric) SET search_path = public;
ALTER FUNCTION public.delete_embalagem(uuid) SET search_path = public;
ALTER FUNCTION public.create_produto_completo(uuid, jsonb, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION public.update_produto_completo(uuid, jsonb, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION public.delete_produto(uuid) SET search_path = public;
ALTER FUNCTION public.create_produto_imagem(uuid, text, text, text, bigint) SET search_path = public;
ALTER FUNCTION public.create_servico(uuid, text, numeric, public.situacao_servico) SET search_path = public;
ALTER FUNCTION public.update_servico(uuid, text, numeric, public.situacao_servico) SET search_path = public;
ALTER FUNCTION public.delete_servico(uuid) SET search_path = public;
ALTER FUNCTION public.set_papel_permissions(uuid, text[]) SET search_path = public;
ALTER FUNCTION public.check_cpf_exists(uuid, text) SET search_path = public;
ALTER FUNCTION public.check_cnpj_exists(uuid, text) SET search_path = public;
ALTER FUNCTION public.create_empresa_and_link_owner_client(text, text, text) SET search_path = public;
