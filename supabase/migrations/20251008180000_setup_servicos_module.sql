-- Habilita a extensão pgcrypto se ainda não estiver habilitada
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. CRIAÇÃO DA TABELA `servicos`
-- Tabela para armazenar os serviços oferecidos pela empresa.
CREATE TABLE IF NOT EXISTS public.servicos (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL,
    descricao text NOT NULL,
    preco numeric(10, 2) NOT NULL DEFAULT 0.00,
    situacao text NOT NULL DEFAULT 'Ativo'::text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT servicos_pkey PRIMARY KEY (id),
    CONSTRAINT servicos_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT servicos_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id),
    CONSTRAINT servicos_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id)
);

-- Comentários para clareza
COMMENT ON TABLE public.servicos IS 'Catálogo de serviços prestados pela empresa.';
COMMENT ON COLUMN public.servicos.preco IS 'Preço de venda padrão do serviço.';
COMMENT ON COLUMN public.servicos.situacao IS 'Situação do serviço (Ativo, Inativo).';

-- 2. POLÍTICAS DE SEGURANÇA (RLS)
-- Habilita a segurança de nível de linha para a tabela
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;

-- Garante que o dono da tabela possa fazer tudo
ALTER TABLE public.servicos OWNER TO postgres;

-- Política: Usuários só podem ver/modificar serviços da própria empresa.
CREATE POLICY "Allow full access to own company services"
ON public.servicos
FOR ALL
USING (is_member_of_empresa(empresa_id))
WITH CHECK (is_member_of_empresa(empresa_id));

-- 3. TRIGGERS DE AUDITORIA
-- Trigger para `created_by` e `updated_by`
CREATE TRIGGER set_servicos_audit_columns
BEFORE INSERT OR UPDATE ON public.servicos
FOR EACH ROW
EXECUTE FUNCTION public.set_audit_columns();

-- Trigger para `updated_at`
CREATE TRIGGER handle_updated_at_servicos
BEFORE UPDATE ON public.servicos
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- 4. FUNÇÕES RPC (CREATE, UPDATE, DELETE)
-- Função para CRIAR um serviço
CREATE OR REPLACE FUNCTION public.create_servico(
    p_empresa_id uuid,
    p_descricao text,
    p_preco numeric,
    p_situacao text
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
    RAISE EXCEPTION 'Permissão negada: usuário não pertence à empresa.';
  END IF;

  INSERT INTO public.servicos (empresa_id, descricao, preco, situacao)
  VALUES (p_empresa_id, p_descricao, p_preco, p_situacao)
  RETURNING id INTO new_id;

  RETURN new_id;
END;
$$;

-- Função para ATUALIZAR um serviço
CREATE OR REPLACE FUNCTION public.update_servico(
    p_id uuid,
    p_descricao text,
    p_preco numeric,
    p_situacao text
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
    RAISE EXCEPTION 'Serviço não encontrado.';
  END IF;

  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Permissão negada: usuário não pertence à empresa do serviço.';
  END IF;

  UPDATE public.servicos
  SET
    descricao = p_descricao,
    preco = p_preco,
    situacao = p_situacao
  WHERE id = p_id;
END;
$$;

-- Função para DELETAR um serviço
CREATE OR REPLACE FUNCTION public.delete_servico(p_id uuid)
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
    RAISE EXCEPTION 'Serviço não encontrado.';
  END IF;

  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Permissão negada para deletar este serviço.';
  END IF;

  DELETE FROM public.servicos WHERE id = p_id;
END;
$$;
