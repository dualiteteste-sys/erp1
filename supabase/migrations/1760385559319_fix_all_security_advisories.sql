/*
          # [Security Fix] Set search_path for all functions
          [This operation applies a security best practice by setting a fixed `search_path` for all user-defined database functions. This prevents potential security vulnerabilities related to path manipulation.]

          ## Query Description: [This script will alter multiple existing functions to enhance security. It is a safe, non-destructive operation that does not modify any data or core logic. It only adds a security configuration to each function.]
          
          ## Metadata:
          - Schema-Category: ["Security", "Safe"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - This will alter approximately 14-20 functions in the `public` schema.
          
          ## Security Implications:
          - RLS Status: [Not Affected]
          - Policy Changes: [No]
          - Auth Requirements: [None]
          
          ## Performance Impact:
          - Indexes: [None]
          - Triggers: [None]
          - Estimated Impact: [Negligible. This is a metadata configuration change.]
          */

-- Trigger Functions
ALTER FUNCTION public.handle_new_user() SET search_path = public;

-- Empresa Functions
ALTER FUNCTION public.create_empresa_and_link_owner_client(text, text, text) SET search_path = public;
ALTER FUNCTION public.delete_empresa_if_member(uuid) SET search_path = public;

-- Cliente/Fornecedor Functions
ALTER FUNCTION public.create_cliente_fornecedor_completo(uuid, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION public.update_cliente_fornecedor_completo(uuid, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION public.delete_cliente_fornecedor_if_member(uuid) SET search_path = public;
ALTER FUNCTION public.create_cliente_anexo(uuid, uuid, text, text, text, integer) SET search_path = public;

-- Produto Functions
ALTER FUNCTION public.create_produto_completo(uuid, jsonb, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION public.update_produto_completo(uuid, jsonb, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION public.delete_produto(uuid) SET search_path = public;
ALTER FUNCTION public.create_produto_imagem(uuid, text, text, text, integer) SET search_path = public;

-- Embalagem Functions
ALTER FUNCTION public.create_embalagem(uuid, text, text, numeric, numeric, numeric, numeric, numeric) SET search_path = public;
ALTER FUNCTION public.update_embalagem(uuid, text, text, numeric, numeric, numeric, numeric, numeric) SET search_path = public;
ALTER FUNCTION public.delete_embalagem(uuid) SET search_path = public;

-- Servico Functions
ALTER FUNCTION public.create_servico(uuid, text, numeric, text) SET search_path = public;
ALTER FUNCTION public.update_servico(uuid, text, numeric, text) SET search_path = public;
ALTER FUNCTION public.delete_servico(uuid) SET search_path = public;

-- Papel/Permissao Functions
ALTER FUNCTION public.set_papel_permissions(uuid, text[]) SET search_path = public;

-- Validation Functions
ALTER FUNCTION public.check_cpf_exists(uuid, text) SET search_path = public;
ALTER FUNCTION public.check_cnpj_exists(uuid, text) SET search_path = public;
