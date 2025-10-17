-- DO block to apply RLS policies to all tables in the public schema
DO $$
DECLARE
    v_table_name TEXT;
    v_policy_name TEXT;
BEGIN
    -- Ensure the helper function exists and is secure
    CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
    RETURNS boolean AS
    $$
    BEGIN
        RETURN EXISTS (
            SELECT 1
            FROM public.empresa_usuarios eu
            WHERE eu.user_id = p_user_id AND eu.empresa_id = p_empresa_id
        );
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    -- Secure the function by setting a specific search_path
    ALTER FUNCTION private.is_member_of_empresa(uuid, uuid) SET search_path = '';

    -- Loop through all tables in the public schema
    FOR v_table_name IN
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    LOOP
        -- Check if RLS is enabled for the table (unambiguous query)
        IF (
            SELECT c.relrowsecurity
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relname = v_table_name AND n.nspname = 'public'
        ) THEN
            -- Handle the 'empresas' table as a special case
            IF v_table_name = 'empresas' THEN
                v_policy_name := 'Membros podem ver sua própria empresa';
                EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I;', v_policy_name, v_table_name);
                EXECUTE format('
                    CREATE POLICY %I ON public.%I
                    FOR SELECT USING (id IN (
                        SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = auth.uid()
                    ));', v_policy_name, v_table_name);
            -- Handle other tables that have an empresa_id column
            ELSIF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'public' AND information_schema.columns.table_name = v_table_name AND column_name = 'empresa_id'
            ) THEN
                v_policy_name := 'Membros podem gerenciar dados da sua empresa';
                EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I;', v_policy_name, v_table_name);
                EXECUTE format('
                    CREATE POLICY %I ON public.%I
                    FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));', v_policy_name, v_table_name);
            END IF;
        END IF;
    END LOOP;
END;
$$;
