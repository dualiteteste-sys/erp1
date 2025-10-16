/*
          # [Recreate update_servico Function]
          [This script drops the old version of the 'update_servico' function and recreates it with the correct parameters to match the application's requirements. This fixes the 'function not found' error during service updates.]
          ## Query Description: [This operation safely drops and recreates a database function. It does not affect any stored data. It is a structural change to align the database with the application code.]
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [false]
          ## Structure Details:
          - Functions affected: public.update_servico
          ## Security Implications:
          - RLS Status: [Not Applicable]
          - Policy Changes: [No]
          - Auth Requirements: [Superuser to alter functions]
          ## Performance Impact:
          - Indexes: [No changes]
          - Triggers: [No changes]
          - Estimated Impact: [None. This is a metadata change.]
          */

-- Drop old version with 4 arguments, if it exists
DROP FUNCTION IF EXISTS public.update_servico(uuid, text, numeric, public.situacao_servico);

-- Drop current 10-argument version, in case it's malformed or has a different signature
DROP FUNCTION IF EXISTS public.update_servico(uuid, text, numeric, public.situacao_servico, text, text, text, text, text, text);

-- Recreate the correct version with 10 arguments
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
  -- Check if the user is a member of the company that owns the service
  SELECT empresa_id INTO v_empresa_id FROM public.servicos WHERE id = p_id;
  
  IF v_empresa_id IS NULL THEN
    RAISE EXCEPTION 'Serviço não encontrado';
  END IF;

  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não pertence à empresa do serviço';
  END IF;

  -- Update the service record
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
