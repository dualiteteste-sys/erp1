/*
  # [Function] create_cliente_anexo
  [Cria um novo registro de anexo para um cliente e o associa à empresa correta.]

  ## Query Description: [Cria uma função SQL segura para inserir registros na tabela `clientes_anexos`. Esta função verifica se o usuário autenticado pertence à empresa antes de permitir a inserção, garantindo a integridade dos dados e o isolamento entre tenants. A função é `SECURITY DEFINER`, permitindo que ela execute com privilégios elevados para inserir o registro, mas a verificação de permissão interna garante que apenas usuários autorizados possam usá-la.]
  
  ## Metadata:
  - Schema-Category: ["Structural"]
  - Impact-Level: ["Low"]
  - Requires-Backup: [false]
  - Reversible: [true]
  
  ## Structure Details:
  - Function: `public.create_cliente_anexo`
  
  ## Security Implications:
  - RLS Status: [Enabled]
  - Policy Changes: [No]
  - Auth Requirements: [Authenticated user, member of the company]
  
  ## Performance Impact:
  - Indexes: [N/A]
  - Triggers: [N/A]
  - Estimated Impact: [Low. A função é executada apenas durante o upload de anexos.]
*/
CREATE OR REPLACE FUNCTION public.create_cliente_anexo(
    p_empresa_id uuid,
    p_cliente_id uuid,
    p_storage_path text,
    p_filename text,
    p_content_type text,
    p_tamanho_bytes integer
)
RETURNS clientes_anexos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_anexo clientes_anexos;
BEGIN
  -- Verifica se o usuário autenticado é membro da empresa
  IF NOT is_member_of(auth.uid(), p_empresa_id) THEN
    RAISE EXCEPTION 'Permissão negada: O usuário não é membro da empresa especificada.';
  END IF;

  INSERT INTO public.clientes_anexos (empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
  VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING * INTO new_anexo;

  RETURN new_anexo;
END;
$$;
