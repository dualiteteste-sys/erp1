/*
          # [Operação de Limpeza e Correção]
          Remove funções auxiliares obsoletas e corrige os avisos de segurança restantes.

          ## Query Description: ["Este script remove 3 funções auxiliares que foram criadas em tentativas de migração anteriores e não são mais necessárias. Ele também corrige a configuração de segurança da função `private.is_member_of_empresa`, que é essencial para o sistema. Esta operação é segura e não deve impactar os dados existentes."]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: false
          - Reversible: false
          
          ## Structure Details:
          - Funções Removidas: public.apply_rls_policy, public.apply_permissive_rls_to_all_tables, public.apply_rls_policies_to_all_tables
          - Funções Alteradas: private.is_member_of_empresa
          
          ## Security Implications:
          - RLS Status: [Intacto]
          - Policy Changes: [Não]
          - Auth Requirements: [Nenhum]
          
          ## Performance Impact:
          - Indexes: [Nenhum]
          - Triggers: [Nenhum]
          - Estimated Impact: [Nenhum impacto de performance esperado.]
          */

-- 1. Remove as funções auxiliares obsoletas que estão causando erros.
-- Usar 'IF EXISTS' garante que o script não falhe se as funções já tiverem sido removidas.
DROP FUNCTION IF EXISTS public.apply_rls_policy(text, text);
DROP FUNCTION IF EXISTS public.apply_permissive_rls_to_all_tables();
DROP FUNCTION IF EXISTS public.apply_rls_policies_to_all_tables();

-- 2. Corrige a configuração de segurança da função essencial 'is_member_of_empresa'.
-- Isso deve resolver os avisos de segurança restantes.
ALTER FUNCTION private.is_member_of_empresa(p_user_id uuid)
SET search_path = public;
