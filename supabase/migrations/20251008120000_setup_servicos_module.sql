/*
          # [Function] is_member_of_empresa
          Cria uma função de segurança para verificar se o usuário autenticado pertence a uma empresa específica.

          ## Query Description: ["Esta função é um pilar para a segurança multi-tenant do sistema. Ela consulta a tabela `empresa_usuarios` para garantir que um usuário só possa acessar ou modificar dados da empresa à qual ele está associado. Não há risco para os dados existentes."]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          ["Cria a função `public.is_member_of_empresa(uuid)`."]
          
          ## Security Implications:
          - RLS Status: [N/A]
          - Policy Changes: [No]
          - Auth Requirements: [auth.uid()]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: ["Baixo. A função é otimizada para verificações rápidas de pertencimento."]
          */
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios
    WHERE empresa_id = p_empresa_id
      AND user_id = auth.uid()
  );
END;
$$;

/*
          # [Table] servicos
          Cria a tabela para armazenar os serviços oferecidos.

          ## Query Description: ["Esta operação cria uma nova tabela `servicos` para o cadastro de serviços. Nenhum dado existente será afetado."]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          ["Tabela: servicos (id, empresa_id, descricao, preco, situacao, created_at, updated_at)"]
          
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [Yes]
          - Auth Requirements: [auth.uid()]
          
          ## Performance Impact:
          - Indexes: ["Índices de chave primária e estrangeira serão criados."]
          - Triggers: [N/A]
          - Estimated Impact: ["Baixo."]
          */
CREATE TABLE IF NOT EXISTS public.servicos (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL,
    descricao text NOT NULL,
    preco numeric(10, 2) NOT NULL DEFAULT 0,
    situacao text NOT NULL DEFAULT 'Ativo'::text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT servicos_pkey PRIMARY KEY (id),
    CONSTRAINT servicos_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE
);

ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow members to manage their own company servicos"
ON public.servicos
FOR ALL
USING (public.is_member_of_empresa(empresa_id))
WITH CHECK (public.is_member_of_empresa(empresa_id));

/*
          # [Function] create_servico
          Cria uma função para inserir um novo serviço.

          ## Query Description: ["Cria uma função RPC para adicionar um novo serviço de forma segura, garantindo que o usuário pertence à empresa."]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          ["Função: create_servico"]
          
          ## Security Implications:
          - RLS Status: [N/A]
          - Policy Changes: [No]
          - Auth Requirements: [auth.uid()]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: ["Baixo."]
          */
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
    v_id uuid;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    INSERT INTO public.servicos (empresa_id, descricao, preco, situacao)
    VALUES (p_empresa_id, p_descricao, p_preco, p_situacao)
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

/*
          # [Function] update_servico
          Cria uma função para atualizar um serviço existente.

          ## Query Description: ["Cria uma função RPC para atualizar um serviço de forma segura."]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          ["Função: update_servico"]
          
          ## Security Implications:
          - RLS Status: [N/A]
          - Policy Changes: [No]
          - Auth Requirements: [auth.uid()]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: ["Baixo."]
          */
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

    IF v_empresa_id IS NULL OR NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied or service not found';
    END IF;

    UPDATE public.servicos
    SET
        descricao = COALESCE(p_descricao, descricao),
        preco = COALESCE(p_preco, preco),
        situacao = COALESCE(p_situacao, situacao),
        updated_at = now()
    WHERE id = p_id;
END;
$$;

/*
          # [Function] delete_servico
          Cria uma função para deletar um serviço.

          ## Query Description: ["Cria uma função RPC para deletar um serviço de forma segura."]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Medium"]
          - Requires-Backup: [true]
          - Reversible: [false]
          
          ## Structure Details:
          ["Função: delete_servico"]
          
          ## Security Implications:
          - RLS Status: [N/A]
          - Policy Changes: [No]
          - Auth Requirements: [auth.uid()]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: ["Baixo."]
          */
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

    IF v_empresa_id IS NULL OR NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied or service not found';
    END IF;

    DELETE FROM public.servicos WHERE id = p_id;
END;
$$;
