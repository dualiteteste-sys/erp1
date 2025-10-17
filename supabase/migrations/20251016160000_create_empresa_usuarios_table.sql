/*
          # Criação da Tabela de Ligação Usuário-Empresa
          [Este script cria a tabela 'empresa_usuarios' que é essencial para o sistema de multi-tenancy, associando usuários a empresas. Também cria a função 'get_empresa_id_for_user' que depende desta tabela.]

          ## Query Description: [Cria a tabela 'empresa_usuarios' para vincular usuários a empresas e define a função 'get_empresa_id_for_user' para recuperar o ID da empresa de um usuário. Esta é uma operação estrutural segura e não afeta dados existentes.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - Tabela 'empresa_usuarios' (nova)
          - Função 'get_empresa_id_for_user' (nova)
          
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [No]
          - Auth Requirements: [N/A]
          
          ## Performance Impact:
          - Indexes: [Primary Key on (empresa_id, user_id)]
          - Triggers: [No]
          - Estimated Impact: [Nenhum impacto de performance esperado em sistemas existentes.]
          */

-- Cria a tabela para associar usuários a empresas
CREATE TABLE IF NOT EXISTS public.empresa_usuarios (
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role text NOT NULL DEFAULT 'member',
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (empresa_id, user_id)
);

-- Habilita RLS na nova tabela
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;

-- Cria a função para obter o ID da empresa de um usuário
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = p_user_id LIMIT 1;
$$;
