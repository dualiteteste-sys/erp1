-- Adiciona funções auxiliares essenciais para RLS e lógica de negócio.

/*
          # [Operation Name]
          Criação de Funções Auxiliares de Tenancy

          ## Query Description: [Este script cria duas funções essenciais no schema `private` para gerenciar a multilocação (multi-tenancy) e as permissões. A função `is_member_of_empresa` verifica se o usuário logado pertence a uma determinada empresa, sendo crucial para as políticas de segurança de linha (RLS). A função `get_empresa_id_for_user` obtém o ID da primeira empresa associada a um usuário, simplificando a inserção de novos dados. A criação destas funções não afeta dados existentes e é um passo preparatório para novos módulos.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - Cria a função `private.is_member_of_empresa(uuid)`.
          - Cria a função `private.get_empresa_id_for_user(uuid)`.
          
          ## Security Implications:
          - RLS Status: [Não aplicável]
          - Policy Changes: [Não]
          - Auth Requirements: [As funções usam `auth.uid()` internamente.]
          
          ## Performance Impact:
          - Indexes: [Nenhum]
          - Triggers: [Nenhum]
          - Estimated Impact: [Nenhum impacto perceptível na performance.]
          */

CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios eu
    WHERE eu.empresa_id = p_empresa_id
      AND eu.user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SELECT empresa_id INTO v_empresa_id
  FROM public.empresa_usuarios
  WHERE user_id = p_user_id
  LIMIT 1;
  
  RETURN v_empresa_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
