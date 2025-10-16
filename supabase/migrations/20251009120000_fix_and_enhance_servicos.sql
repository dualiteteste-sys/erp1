/*
          # [Fix and Enhance Servicos v3]
          [This script robustly creates the 'situacao_servico' type, adds new fields to the 'servicos' table, and recreates its related functions to ensure module functionality.]
          ## Query Description: [This operation defensively creates a new type, alters the 'servicos' table to add all required columns, and recreates the functions to manage them. It is designed to be safe and should not affect existing data, but a backup is always recommended before schema changes.]
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Medium"]
          - Requires-Backup: [true]
          - Reversible: [false]
          ## Structure Details:
          - Tables affected: public.servicos
          - Types created: public.situacao_servico
          - Functions affected: public.create_servico, public.update_servico
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [No]
          - Auth Requirements: [Authenticated user, member of the company]
          ## Performance Impact:
          - Indexes: [No changes]
          - Triggers: [No changes]
          - Estimated Impact: [Low. The operation is fast and should not impact database performance.]
*/
-- Step 1: Create the ENUM type if it doesn't exist.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'situacao_servico') THEN
        CREATE TYPE public.situacao_servico AS ENUM ('Ativo', 'Inativo');
    END IF;
END$$;
-- Step 2: Ensure the 'servicos' table exists. If not, create it with a temporary type for 'situacao'.
CREATE TABLE IF NOT EXISTS public.servicos (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    preco numeric(10, 2) NOT NULL DEFAULT 0,
    situacao text NOT NULL DEFAULT 'Ativo', -- Use text temporarily
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
-- Step 3: Add all required columns if they don't exist.
ALTER TABLE public.servicos ADD COLUMN IF NOT EXISTS codigo text;
ALTER TABLE public.servicos ADD COLUMN IF NOT EXISTS unidade text;
ALTER TABLE public.servicos ADD COLUMN IF NOT EXISTS codigo_servico text;
ALTER TABLE public.servicos ADD COLUMN IF NOT EXISTS nbs text;
ALTER TABLE public.servicos ADD COLUMN IF NOT EXISTS descricao_complementar text;
ALTER TABLE public.servicos ADD COLUMN IF NOT EXISTS observacoes text;
-- Step 4: Alter the 'situacao' column to the correct ENUM type.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'servicos' 
        AND column_name = 'situacao' 
        AND udt_name != 'situacao_servico'
    ) THEN
        ALTER TABLE public.servicos ALTER COLUMN situacao TYPE public.situacao_servico USING situacao::text::public.situacao_servico;
        ALTER TABLE public.servicos ALTER COLUMN situacao SET DEFAULT 'Ativo'::public.situacao_servico;
    END IF;
END $$;
-- Step 5: Re-apply RLS policies to be safe.
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Servicos members can do all actions" ON public.servicos;
CREATE POLICY "Servicos members can do all actions"
ON public.servicos
FOR ALL
USING (is_member_of_empresa(empresa_id));
-- Step 6: Recreate the RPC functions with the correct signature.
DROP FUNCTION IF EXISTS public.create_servico(uuid,text,numeric,public.situacao_servico,text,text,text,text,text,text);
DROP FUNCTION IF EXISTS public.update_servico(uuid,text,numeric,public.situacao_servico,text,text,text,text,text,text);
-- CREATE function
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
SET search_path = public
AS $$
DECLARE
  new_id uuid;
BEGIN
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não pertence à empresa';
  END IF;
  INSERT INTO public.servicos (empresa_id, descricao, preco, situacao, codigo, unidade, codigo_servico, nbs, descricao_complementar, observacoes)
  VALUES (p_empresa_id, p_descricao, p_preco, p_situacao, p_codigo, p_unidade, p_codigo_servico, p_nbs, p_descricao_complementar, p_observacoes)
  RETURNING id INTO new_id;
  RETURN new_id;
END;
$$;
-- UPDATE function
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
  SELECT empresa_id INTO v_empresa_id FROM public.servicos WHERE id = p_id;
  IF v_empresa_id IS NULL THEN
    RAISE EXCEPTION 'Serviço não encontrado';
  END IF;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não pertence à empresa do serviço';
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
