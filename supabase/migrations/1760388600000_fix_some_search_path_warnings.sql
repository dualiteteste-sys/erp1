/*
  # [SECURITY] Fix Function Search Path Warnings (Partial)
  This migration addresses several "Function Search Path Mutable" warnings by explicitly setting the search_path for known trigger functions. This is a security best practice to prevent potential hijacking attacks.

  ## Query Description: 
  This operation modifies the metadata of existing functions. It is a safe, non-destructive change that does not affect data or table structures. It only enhances the security of the function execution environment.

  ## Metadata:
  - Schema-Category: "Security"
  - Impact-Level: "Low"
  - Requires-Backup: false
  - Reversible: true (by altering the function back)

  ## Structure Details:
  - Functions affected:
    - app.set_updated_at()
    - public.update_updated_by_column()
    - public.trg_set_empresa_id_produto_imagens()

  ## Security Implications:
  - RLS Status: Unchanged
  - Policy Changes: No
  - Auth Requirements: Migration requires admin privileges.

  ## Performance Impact:
  - Indexes: None
  - Triggers: None
  - Estimated Impact: Negligible. This is a metadata change.
*/

-- This function is a common trigger for setting the 'updated_at' timestamp.
-- It is assumed to have no arguments.
ALTER FUNCTION app.set_updated_at()
SET search_path = 'public';

-- This function appears to be a trigger for setting an 'updated_by' column.
-- It is assumed to have no arguments.
ALTER FUNCTION public.update_updated_by_column()
SET search_path = 'public';

-- This function name suggests it's a trigger for setting 'empresa_id' on 'produto_imagens' table.
-- It is assumed to have no arguments.
ALTER FUNCTION public.trg_set_empresa_id_produto_imagens()
SET search_path = 'public';
