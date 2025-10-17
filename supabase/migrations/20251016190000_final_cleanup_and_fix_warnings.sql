/*
  # [Operação Final de Limpeza e Correção de Segurança]
  Este script realiza a limpeza definitiva de artefatos de migrações anteriores e corrige os avisos de segurança restantes.

  ## Query Description:
  1.  **DROP PROCEDURE**: Remove o procedimento `apply_permissive_rls_to_all_tables` que estava causando o erro "cannot change routine kind".
  2.  **DROP FUNCTION**: Remove as funções auxiliares `apply_rls_policy` e `apply_rls_policies_to_all_tables` que não são mais necessárias.
  3.  **ALTER FUNCTION**: Corrige o `search_path` da função de segurança `is_member_of_empresa`, que era a causa dos avisos de segurança restantes.
  
  Esta operação é segura, pois apenas remove código obsoleto e corrige uma configuração de segurança, sem afetar dados ou a estrutura principal da aplicação.

  ## Metadata:
  - Schema-Category: ["Structural", "Safe"]
  - Impact-Level: ["Low"]
  - Requires-Backup: false
  - Reversible: false (as funções removidas são desnecessárias)
*/

-- 1. Remove o PROCEDURE que estava causando o erro.
DROP PROCEDURE IF EXISTS public.apply_permissive_rls_to_all_tables();

-- 2. Remove as outras duas funções "fantasmas".
DROP FUNCTION IF EXISTS public.apply_rls_policy();
DROP FUNCTION IF EXISTS public.apply_rls_policies_to_all_tables();

-- 3. Corrige a função de segurança essencial que ainda causa o warning.
ALTER FUNCTION private.is_member_of_empresa(p_user_id uuid)
SET search_path = public;
