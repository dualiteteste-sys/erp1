-- Remove a função existente que está causando o conflito.
-- O IF EXISTS garante que o script não falhe se a função já tiver sido removida.
DROP FUNCTION IF EXISTS public.create_cliente_anexo(uuid, uuid, text, text, text, bigint);

-- Recria a função com a assinatura e o corpo corretos.
-- Esta versão retorna a linha completa da tabela 'clientes_anexos',
-- o que é esperado pela aplicação.
CREATE OR REPLACE FUNCTION public.create_cliente_anexo(
    p_empresa_id uuid,
    p_cliente_id uuid,
    p_storage_path text,
    p_filename text,
    p_content_type text,
    p_tamanho_bytes bigint
)
RETURNS clientes_anexos -- Define o tipo de retorno como a própria tabela.
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_anexo clientes_anexos;
BEGIN
  -- Verifica se o usuário tem permissão para atuar na empresa especificada.
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não autorizado para esta empresa.';
  END IF;

  -- Insere o novo registro na tabela de anexos.
  INSERT INTO public.clientes_anexos (
    empresa_id,
    cliente_fornecedor_id,
    storage_path,
    filename,
    content_type,
    tamanho_bytes,
    bucket
  )
  VALUES (
    p_empresa_id,
    p_cliente_id,
    p_storage_path,
    p_filename,
    p_content_type,
    p_tamanho_bytes,
    'clientes_anexos' -- Nome do bucket no Supabase Storage.
  )
  RETURNING * INTO new_anexo; -- Captura a linha recém-criada na variável.

  -- Retorna a linha completa do novo anexo.
  RETURN new_anexo;
END;
$$;
