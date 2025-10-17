/*
# Criação da tabela de associação de usuários e empresas

Esta migração cria a tabela `empresa_usuarios`, que é fundamental para o funcionamento da multi-tenancy no sistema. Ela estabelece a ligação entre um usuário (`auth.users`) e uma empresa (`public.empresas`).

## Descrição da Query:
- **Cria a tabela `empresa_usuarios`**: Define as colunas `empresa_id` e `user_id` como chaves estrangeiras.
- **Habilita RLS**: Ativa a Segurança em Nível de Linha (Row Level Security) para proteger os dados.
- **Cria Política de Acesso**: Adiciona uma política que permite que cada usuário veja apenas a sua própria associação com empresas, garantindo a privacidade.
- **Cria a função `get_empresa_id_for_user`**: Esta função auxiliar, que estava faltando e causando erros, é criada para obter a primeira empresa associada a um usuário.

Esta correção é um passo crucial para estabilizar o banco de dados e resolver os erros de dependência.

## Metadados:
- Schema-Category: "Structural"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true (com a remoção da tabela e da função)

## Detalhes da Estrutura:
- **Tabela Adicionada**: `public.empresa_usuarios`
- **Função Adicionada**: `public.get_empresa_id_for_user(uuid)`

## Implicações de Segurança:
- RLS Status: Habilitado na nova tabela.
- Policy Changes: Adicionada política de seleção na nova tabela.
- Auth Requirements: A função `get_empresa_id_for_user` é `SECURITY INVOKER`.

## Impacto de Performance:
- Indexes: Chave primária e chaves estrangeiras são indexadas automaticamente.
- Triggers: Nenhum.
- Estimated Impact: Baixo. Apenas adiciona uma nova tabela e função.
*/

-- 1. Criar a tabela para associar usuários a empresas
CREATE TABLE IF NOT EXISTS public.empresa_usuarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT empresa_usuarios_empresa_id_user_id_key UNIQUE (empresa_id, user_id)
);

-- Comentários para clareza
COMMENT ON TABLE public.empresa_usuarios IS 'Associa usuários a empresas, definindo a qual empresa cada usuário pertence.';
COMMENT ON COLUMN public.empresa_usuarios.empresa_id IS 'ID da empresa.';
COMMENT ON COLUMN public.empresa_usuarios.user_id IS 'ID do usuário (de auth.users).';

-- 2. Habilitar RLS na nova tabela
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;

-- 3. Criar políticas de segurança para a nova tabela
DROP POLICY IF EXISTS "Allow users to see their own membership" ON public.empresa_usuarios;
CREATE POLICY "Allow users to see their own membership"
ON public.empresa_usuarios
FOR SELECT
USING (auth.uid() = user_id);

-- Por padrão, INSERT, UPDATE, DELETE não são permitidos. Serão controlados por funções `SECURITY DEFINER`.

-- 4. Criar a função auxiliar que estava faltando
CREATE OR REPLACE FUNCTION public.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  RETURN (
    SELECT empresa_id
    FROM public.empresa_usuarios
    WHERE user_id = p_user_id
    LIMIT 1
  );
END;
$$;
