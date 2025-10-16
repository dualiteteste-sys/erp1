/*
          # [Create Vendedores Module]
          [This script creates the 'vendedores' table, its related security policies, and RPC functions for CRUD operations.]
          ## Query Description: [This operation adds a new 'vendedores' table and its management functions to the database. It is a structural change and should not affect existing data. A backup is always recommended before schema changes.]
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Medium"]
          - Requires-Backup: [true]
          - Reversible: [false]
          ## Structure Details:
          - Tables affected: public.vendedores
          - Functions affected: public.create_vendedor, public.update_vendedor, public.delete_vendedor
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [Yes, new policies for 'vendedores' table]
          - Auth Requirements: [Authenticated user, member of the company]
          ## Performance Impact:
          - Indexes: [New indexes on 'vendedores' table for performance]
          - Triggers: [No new triggers]
          - Estimated Impact: [Low. The operation is fast and should not impact database performance.]
*/
-- 1. Create ENUM types if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'situacao_vendedor') THEN
        CREATE TYPE public.situacao_vendedor AS ENUM ('Ativo', 'Inativo');
    END IF;
END$$;
-- 2. Create Vendedores Table
CREATE TABLE IF NOT EXISTS public.vendedores (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL,
    nome text NOT NULL,
    email text,
    cpf_cnpj text,
    situacao public.situacao_vendedor NOT NULL DEFAULT 'Ativo'::public.situacao_vendedor,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT vendedores_pkey PRIMARY KEY (id),
    CONSTRAINT vendedores_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT vendedores_empresa_id_email_key UNIQUE (empresa_id, email)
);
-- 3. Add Indexes
CREATE INDEX IF NOT EXISTS idx_vendedores_empresa_id ON public.vendedores(empresa_id);
-- 4. Enable RLS
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;
-- 5. Create RLS Policies
DROP POLICY IF EXISTS "Vendedores members can do all actions" ON public.vendedores;
CREATE POLICY "Vendedores members can do all actions"
ON public.vendedores
FOR ALL
USING (is_member_of_empresa(empresa_id));
-- 6. Create RPC Functions
-- CREATE
CREATE OR REPLACE FUNCTION public.create_vendedor(
    p_empresa_id uuid,
    p_nome text,
    p_email text,
    p_cpf_cnpj text,
    p_situacao public.situacao_vendedor
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
  INSERT INTO public.vendedores (empresa_id, nome, email, cpf_cnpj, situacao)
  VALUES (p_empresa_id, p_nome, p_email, p_cpf_cnpj, p_situacao)
  RETURNING id INTO new_id;
  RETURN new_id;
END;
$$;
-- UPDATE
CREATE OR REPLACE FUNCTION public.update_vendedor(
    p_id uuid,
    p_nome text,
    p_email text,
    p_cpf_cnpj text,
    p_situacao public.situacao_vendedor
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SELECT empresa_id INTO v_empresa_id FROM public.vendedores WHERE id = p_id;
  IF v_empresa_id IS NULL THEN
    RAISE EXCEPTION 'Vendedor não encontrado';
  END IF;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não pertence à empresa do vendedor';
  END IF;
  UPDATE public.vendedores
  SET
    nome = p_nome,
    email = p_email,
    cpf_cnpj = p_cpf_cnpj,
    situacao = p_situacao,
    updated_at = now()
  WHERE id = p_id;
END;
$$;
-- DELETE
CREATE OR REPLACE FUNCTION public.delete_vendedor(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.vendedores WHERE id = p_id;
    IF v_empresa_id IS NULL THEN
        RAISE EXCEPTION 'Vendedor não encontrado';
    END IF;
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não tem permissão para excluir este vendedor.';
    END IF;
    DELETE FROM public.vendedores WHERE id = p_id;
END;
$$;
