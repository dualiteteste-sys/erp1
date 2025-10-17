/*
          # [SECURITY] Fix Remaining Mutable Function Search Paths
          [This script sets a secure `search_path` for all remaining user-defined functions in the `public` schema to resolve all `Function Search Path Mutable` warnings.]

          ## Query Description: [This operation inspects all custom functions in the database and applies a security setting to prevent potential misuse. It is a safe, non-destructive operation that improves the security posture of your project without affecting data or functionality.]
          
          ## Metadata:
          - Schema-Category: ["Security"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - This script does not alter table structures. It modifies the metadata of existing functions.
          
          ## Security Implications:
          - RLS Status: [Not Affected]
          - Policy Changes: [No]
          - Auth Requirements: [None]
          - This operation is designed to fix a security vulnerability.
          
          ## Performance Impact:
          - Indexes: [Not Affected]
          - Triggers: [Not Affected]
          - Estimated Impact: [None. This is a metadata change with no impact on query performance.]
          */
DO $$
DECLARE
    function_signature TEXT;
BEGIN
    -- Loop through all functions in the 'public' schema owned by 'postgres' (the default owner for user-created functions)
    FOR function_signature IN
        SELECT
            -- Format is: schema_name.function_name(arg_types)
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Only functions in the public schema
            AND p.prokind = 'f' -- 'f' for normal functions
            AND NOT EXISTS ( -- Exclude aggregate functions
                SELECT 1
                FROM pg_aggregate
                WHERE aggfnoid = p.oid
            )
            AND p.proname NOT LIKE 'pg_%' -- Exclude internal pg functions
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin')
    LOOP
        -- Set a secure search_path for each function
        BEGIN
            EXECUTE 'ALTER FUNCTION ' || function_signature || ' SET search_path = public;';
            RAISE NOTICE 'Set search_path for function: %', function_signature;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Could not alter function %: %', function_signature, SQLERRM;
        END;
    END LOOP;
END $$;
