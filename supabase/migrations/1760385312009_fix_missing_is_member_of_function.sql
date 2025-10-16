/*
# [MIGRATION] Fix Missing is_member_of Function and RLS Policy
This script corrects an issue where the `is_member_of` helper function might be missing or incorrectly configured, and ensures the associated Row Level Security (RLS) policy for product images is correctly applied.

## Query Description:
- **`is_member_of` Function:** It uses `CREATE OR REPLACE` to define or update the function that checks if the current user is a member of a given company. This is idempotent and safe to run multiple times. It also includes `SET search_path = 'public'` to resolve a security warning.
- **RLS Policy on `storage.objects`:** It first drops any existing policy with the same name to avoid conflicts, and then recreates the policy. This policy ensures that users can only access images belonging to their own company within the `produto-imagens` bucket.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true (the previous state can be restored by removing the policy and function)

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes (recreates the policy for `produto-imagens`)
- Auth Requirements: This function and policy depend on `auth.uid()`.
*/

-- Recreate the function idempotently, now with the search_path fix.
CREATE OR REPLACE FUNCTION public.is_member_of(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios eu
    WHERE eu.empresa_id = p_empresa_id
      AND eu.user_id = auth.uid()
  );
END;
$$;

-- Drop the policy if it exists to prevent creation errors.
DROP POLICY IF EXISTS "Allow members to manage own company images" ON storage.objects;

-- Recreate the RLS policy for the 'produto-imagens' bucket.
CREATE POLICY "Allow members to manage own company images"
ON storage.objects FOR ALL
USING (
  bucket_id = 'produto-imagens' AND public.is_member_of( (storage.foldername(name))[1]::uuid )
)
WITH CHECK (
  bucket_id = 'produto-imagens' AND public.is_member_of( (storage.foldername(name))[1]::uuid )
);
