-- Final Cleanup and Security Fix
-- This script removes old, unnecessary helper functions and correctly sets the search_path on the essential security function.

-- Step 1: Safely drop the old, unnecessary helper functions that are causing errors.
-- These are remnants of previous failed migration attempts and are not part of the application.
-- We use DROP FUNCTION IF EXISTS to avoid errors if they don't exist.
DROP FUNCTION IF EXISTS public.apply_rls_policy(text,text,text);
DROP FUNCTION IF EXISTS public.apply_permissive_rls_to_all_tables();
DROP FUNCTION IF EXISTS public.apply_rls_policies_to_all_tables();

-- Step 2: Correct the search_path for the essential security function.
-- This function is used by all RLS policies to ensure multi-tenancy.
-- Fixing this will resolve the remaining security warnings.
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public
AS $$
BEGIN
  -- Checks if the currently authenticated user is a member of the specified empresa.
  -- This is the core of the multi-tenancy security.
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios eu
    WHERE eu.empresa_id = p_empresa_id
      AND eu.user_id = auth.uid()
  );
END;
$$;
