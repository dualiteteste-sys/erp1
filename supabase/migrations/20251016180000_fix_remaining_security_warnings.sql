/*
          # [SECURITY] Fix Remaining Search Path Warnings
          [This script recreates several functions to explicitly set a secure `search_path`, addressing all remaining 'Function Search Path Mutable' warnings.]

          ## Query Description: [This operation is safe and structural. It redefines existing database functions to improve security by preventing potential unauthorized code execution. No data will be lost, and application functionality will be preserved.]
          
          ## Metadata:
          - Schema-Category: ["Structural", "Safe"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [false]
          
          ## Structure Details:
          [Affects the definitions of the following functions: get_empresa_id_for_user, is_member_of_empresa, check_vendedor_email_exists, create_cliente_anexo, create_produto_imagem]
          
          ## Security Implications:
          - RLS Status: [No change]
          - Policy Changes: [No]
          - Auth Requirements: [None]
          
          ## Performance Impact:
          - Indexes: [No change]
          - Triggers: [No change]
          - Estimated Impact: [None]
          */

-- Recreate helper functions with secure search_path
CREATE OR REPLACE FUNCTION public.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = p_user_id LIMIT 1);
END;
$$;
ALTER FUNCTION public.get_empresa_id_for_user(uuid) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.empresa_usuarios
        WHERE empresa_usuarios.empresa_id = p_empresa_id
        AND empresa_usuarios.user_id = auth.uid()
    );
END;
$$;
ALTER FUNCTION public.is_member_of_empresa(uuid) SET search_path = 'public';

-- Recreate other functions that were causing warnings
CREATE OR REPLACE FUNCTION public.check_vendedor_email_exists(p_empresa_id uuid, p_email text, p_vendedor_id uuid DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.vendedores
    WHERE empresa_id = p_empresa_id
      AND email = p_email
      AND (p_vendedor_id IS NULL OR id <> p_vendedor_id)
  );
END;
$$;
ALTER FUNCTION public.check_vendedor_email_exists(uuid, text, uuid) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_anexo_id uuid;
BEGIN
  IF NOT public.is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não autorizado para esta empresa.';
  END IF;

  INSERT INTO public.clientes_anexos (empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
  VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING id INTO new_anexo_id;

  RETURN new_anexo_id;
END;
$$;
ALTER FUNCTION public.create_cliente_anexo(uuid,uuid,text,text,text,bigint) SET search_path = 'public';


CREATE OR REPLACE FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
    new_imagem_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;

    IF v_empresa_id IS NULL THEN
        RAISE EXCEPTION 'Produto não encontrado.';
    END IF;

    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não autorizado para esta empresa.';
    END IF;

    INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
    VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING id INTO new_imagem_id;

    RETURN new_imagem_id;
END;
$$;
ALTER FUNCTION public.create_produto_imagem(uuid,text,text,text,bigint) SET search_path = 'public';
