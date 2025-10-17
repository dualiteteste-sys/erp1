DO $$
DECLARE
    function_signature TEXT;
BEGIN
    /*
      # [Operation] Fix All Mutable Search Path Warnings
      [This script iterates through all user-created functions in the 'public' schema and sets a secure 'search_path' for each one. This resolves the "Function Search Path Mutable" security advisory by preventing potential hijacking attacks.]

      ## Query Description: [This operation modifies the metadata of existing database functions. It does not alter data or logic but enhances security by explicitly defining the schema search path. It is a safe and recommended procedure.]
      
      ## Metadata:
      - Schema-Category: ["Security", "Structural"]
      - Impact-Level: ["Low"]
      - Requires-Backup: false
      - Reversible: true
      
      ## Structure Details:
      - This affects multiple functions in the 'public' schema.
      
      ## Security Implications:
      - RLS Status: [Not Affected]
      - Policy Changes: [No]
      - Auth Requirements: [None]
      
      ## Performance Impact:
      - Indexes: [Not Affected]
      - Triggers: [Not Affected]
      - Estimated Impact: [None. This is a metadata change with no impact on query performance.]
    */
    FOR function_signature IN
        SELECT
            -- Reconstruct the full function signature required for ALTER FUNCTION
            p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Only functions in the public schema
            AND p.prokind = 'f'   -- 'f' for normal functions
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres') -- Exclude Supabase/Postgres owned functions
    LOOP
        -- Dynamically execute the ALTER FUNCTION command for each function
        EXECUTE 'ALTER FUNCTION public.' || function_signature || ' SET search_path = public;';
    END LOOP;
END;
$$;
