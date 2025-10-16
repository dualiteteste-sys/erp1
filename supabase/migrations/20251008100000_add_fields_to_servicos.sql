-- Adds new fields to the servicos table and updates the corresponding RPC functions.

-- Add new columns to the servicos table
ALTER TABLE public.servicos
ADD COLUMN codigo TEXT,
ADD COLUMN unidade TEXT,
ADD COLUMN codigo_servico TEXT,
ADD COLUMN nbs TEXT,
ADD COLUMN descricao_complementar TEXT,
ADD COLUMN observacoes TEXT;

-- Drop existing functions to be replaced
DROP FUNCTION IF EXISTS public.create_servico(uuid, text, numeric, public.situacao_servico);
DROP FUNCTION IF EXISTS public.update_servico(uuid, text, numeric, public.situacao_servico);

-- Recreate the create_servico function with new fields
CREATE OR REPLACE FUNCTION public.create_servico(
    p_empresa_id uuid,
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
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_id uuid;
BEGIN
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para criar serviços nesta empresa.';
  END IF;

  INSERT INTO public.servicos (
    empresa_id, descricao, preco, situacao, codigo, unidade, codigo_servico, nbs, descricao_complementar, observacoes
  ) VALUES (
    p_empresa_id, p_descricao, p_preco, p_situacao, p_codigo, p_unidade, p_codigo_servico, p_nbs, p_descricao_complementar, p_observacoes
  ) RETURNING id INTO v_new_id;

  RETURN v_new_id;
END;
$$;

-- Recreate the update_servico function with new fields
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
AS $$
BEGIN
  IF NOT is_member_of_empresa((SELECT empresa_id FROM public.servicos WHERE id = p_id)) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para atualizar serviços nesta empresa.';
  END IF;

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
