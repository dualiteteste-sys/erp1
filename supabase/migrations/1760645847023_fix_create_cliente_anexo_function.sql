-- Summary: Corrige a função `create_cliente_anexo` que estava impedindo as migrações.
-- A função está sendo removida e recriada com a assinatura e o tipo de retorno corretos.

-- Passo 1: Remover a função existente com a assinatura antiga, conforme sugerido pelo erro.
DROP FUNCTION IF EXISTS public.create_cliente_anexo(uuid,uuid,text,text,text,bigint);

-- Passo 2: Recriar a função com a estrutura correta, incluindo o tipo de retorno esperado e a configuração de segurança.
CREATE OR REPLACE FUNCTION public.create_cliente_anexo(
    p_empresa_id uuid,
    p_cliente_id uuid,
    p_storage_path text,
    p_filename text,
    p_content_type text,
    p_tamanho_bytes bigint
)
RETURNS clientes_anexos -- Define o tipo de retorno correto, que é a linha da tabela.
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_anexo clientes_anexos;
BEGIN
  -- Garante que o usuário pertence à empresa antes de inserir.
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para acessar esta empresa.';
  END IF;

  INSERT INTO public.clientes_anexos (
    empresa_id,
    cliente_fornecedor_id,
    storage_path,
    filename,
    content_type,
    tamanho_bytes
  )
  VALUES (
    p_empresa_id,
    p_cliente_id,
    p_storage_path,
    p_filename,
    p_content_type,
    p_tamanho_bytes
  )
  RETURNING * INTO new_anexo; -- Retorna a linha recém-criada.

  RETURN new_anexo;
END;
$$;
