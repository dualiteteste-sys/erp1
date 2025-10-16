/*
          # [Recreate update_servico Function]
          [This migration recreates the 'update_servico' function with the correct parameters and security settings to align with the application's requirements.]
          ## Query Description: [This operation drops any old version of the function and creates a new one. It is a safe operation that only affects the function definition and does not impact existing data.]
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [false]
          ## Structure Details:
          - Functions affected: public.update_servico
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [No]
          - Auth Requirements: [Authenticated user, member of the company]
          ## Performance Impact:
          - Indexes: [No changes]
          - Triggers: [No changes]
          - Estimated Impact: [None. This is a function definition change.]
*/
-- Drop a versão antiga para garantir que não haja conflitos
DROP FUNCTION IF EXISTS public.update_servico(uuid,text,numeric,public.situacao_servico,text,text,text,text,text,text);

-- Recria a função com a assinatura e lógica corretas
CREATE OR REPLACE FUNCTION public.update_servico(
    p_id uuid,
    p_descricao text,
    p_preco numeric,
    p_situacao public.situacao_servico,
    p_codigo text,
    p_unidade text,
    p_codigo_servico text,
    p_nbs text,
    p_descricao_complementar text,
    p_observacoes text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  -- Garante que o serviço existe e o usuário tem permissão
  SELECT empresa_id INTO v_empresa_id FROM public.servicos WHERE id = p_id;

  IF v_empresa_id IS NULL THEN
    RAISE EXCEPTION 'Serviço com ID % não encontrado.', p_id;
  END IF;

  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Acesso negado: O usuário não pertence à empresa deste serviço.';
  END IF;

  -- Executa a atualização
  UPDATE public.servicos
  SET
    descricao = p_descricao,
    preco = p_preco,
    situacao = p_situacao,
    codigo = p_codigo,
    unidade = p_unidade,
    codigo_servico = p_codigo_servico,
    nbs = p_nbs,
    descricao_complementar = p_descricao_complementar,
    observacoes = p_observacoes,
    updated_at = now()
  WHERE id = p_id;
END;
$$;
