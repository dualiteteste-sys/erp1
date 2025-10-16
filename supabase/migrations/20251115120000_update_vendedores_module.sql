/*
          # [Update Vendedores Module]
          [This script adds new fields to the 'vendedores' table and updates its related RPC functions to support a more complete data structure.]
          ## Query Description: [This operation alters the 'vendedores' table to add several new columns for detailed information and recreates the management functions. It is a structural change and should not affect existing data. A backup is always recommended before schema changes.]
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Medium"]
          - Requires-Backup: [true]
          - Reversible: [false]
          ## Structure Details:
          - Tables affected: public.vendedores
          - Types created: public.tipo_pessoa_vendedor, public.tipo_contribuinte_icms
          - Functions affected: public.create_vendedor, public.update_vendedor
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [No]
          - Auth Requirements: [Authenticated user, member of the company]
          ## Performance Impact:
          - Indexes: [No changes]
          - Triggers: [No new triggers]
          - Estimated Impact: [Low. The operation is fast and should not impact database performance.]
*/
-- 1. Create ENUM types if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_pessoa_vendedor') THEN
        CREATE TYPE public.tipo_pessoa_vendedor AS ENUM ('PF', 'PJ');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_contribuinte_icms') THEN
        CREATE TYPE public.tipo_contribuinte_icms AS ENUM ('Contribuinte ICMS', 'Contribuinte Isento', 'Não Contribuinte');
    END IF;
    -- Add new values to situacao_vendedor if they don't exist
    ALTER TYPE public.situacao_vendedor ADD VALUE IF NOT EXISTS 'Ativo com acesso ao sistema';
    ALTER TYPE public.situacao_vendedor ADD VALUE IF NOT EXISTS 'Ativo sem acesso ao sistema';
END$$;

-- 2. Add new columns to the 'vendedores' table
ALTER TABLE public.vendedores
    ADD COLUMN IF NOT EXISTS fantasia text,
    ADD COLUMN IF NOT EXISTS codigo text,
    ADD COLUMN IF NOT EXISTS tipo_pessoa public.tipo_pessoa_vendedor NOT NULL DEFAULT 'PF',
    ADD COLUMN IF NOT EXISTS contribuinte_icms public.tipo_contribuinte_icms,
    ADD COLUMN IF NOT EXISTS inscricao_estadual text,
    ADD COLUMN IF NOT EXISTS cep text,
    ADD COLUMN IF NOT EXISTS cidade text,
    ADD COLUMN IF NOT EXISTS uf text,
    ADD COLUMN IF NOT EXISTS logradouro text,
    ADD COLUMN IF NOT EXISTS bairro text,
    ADD COLUMN IF NOT EXISTS numero text,
    ADD COLUMN IF NOT EXISTS complemento text,
    ADD COLUMN IF NOT EXISTS telefone text,
    ADD COLUMN IF NOT EXISTS celular text,
    ADD COLUMN IF NOT EXISTS email_comunicacao text,
    ADD COLUMN IF NOT EXISTS deposito_padrao text;

-- 3. Recreate RPC functions to include new fields
DROP FUNCTION IF EXISTS public.create_vendedor(uuid,text,text,text,public.situacao_vendedor);
CREATE OR REPLACE FUNCTION public.create_vendedor(
    p_empresa_id uuid,
    p_nome text,
    p_email text,
    p_cpf_cnpj text,
    p_situacao public.situacao_vendedor,
    p_fantasia text,
    p_codigo text,
    p_tipo_pessoa public.tipo_pessoa_vendedor,
    p_contribuinte_icms public.tipo_contribuinte_icms,
    p_inscricao_estadual text,
    p_cep text,
    p_cidade text,
    p_uf text,
    p_logradouro text,
    p_bairro text,
    p_numero text,
    p_complemento text,
    p_telefone text,
    p_celular text,
    p_email_comunicacao text,
    p_deposito_padrao text
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
  INSERT INTO public.vendedores (
      empresa_id, nome, email, cpf_cnpj, situacao, fantasia, codigo, tipo_pessoa,
      contribuinte_icms, inscricao_estadual, cep, cidade, uf, logradouro, bairro,
      numero, complemento, telefone, celular, email_comunicacao, deposito_padrao
  )
  VALUES (
      p_empresa_id, p_nome, p_email, p_cpf_cnpj, p_situacao, p_fantasia, p_codigo, p_tipo_pessoa,
      p_contribuinte_icms, p_inscricao_estadual, p_cep, p_cidade, p_uf, p_logradouro, p_bairro,
      p_numero, p_complemento, p_telefone, p_celular, p_email_comunicacao, p_deposito_padrao
  )
  RETURNING id INTO new_id;
  RETURN new_id;
END;
$$;

DROP FUNCTION IF EXISTS public.update_vendedor(uuid,text,text,text,public.situacao_vendedor);
CREATE OR REPLACE FUNCTION public.update_vendedor(
    p_id uuid,
    p_nome text,
    p_email text,
    p_cpf_cnpj text,
    p_situacao public.situacao_vendedor,
    p_fantasia text,
    p_codigo text,
    p_tipo_pessoa public.tipo_pessoa_vendedor,
    p_contribuinte_icms public.tipo_contribuinte_icms,
    p_inscricao_estadual text,
    p_cep text,
    p_cidade text,
    p_uf text,
    p_logradouro text,
    p_bairro text,
    p_numero text,
    p_complemento text,
    p_telefone text,
    p_celular text,
    p_email_comunicacao text,
    p_deposito_padrao text
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
    fantasia = p_fantasia,
    codigo = p_codigo,
    tipo_pessoa = p_tipo_pessoa,
    contribuinte_icms = p_contribuinte_icms,
    inscricao_estadual = p_inscricao_estadual,
    cep = p_cep,
    cidade = p_cidade,
    uf = p_uf,
    logradouro = p_logradouro,
    bairro = p_bairro,
    numero = p_numero,
    complemento = p_complemento,
    telefone = p_telefone,
    celular = p_celular,
    email_comunicacao = p_email_comunicacao,
    deposito_padrao = p_deposito_padrao,
    updated_at = now()
  WHERE id = p_id;
END;
$$;
