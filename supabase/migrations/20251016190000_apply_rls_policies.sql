-- Habilita RLS em todas as tabelas (se já não estiver) e cria as políticas
DO $$
DECLARE
    tbl_name TEXT;
BEGIN
    FOR tbl_name IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_type = 'BASE TABLE' 
          AND table_name NOT LIKE 'pg_%' 
          AND table_name NOT LIKE 'sql_%'
    LOOP
        -- Habilita RLS se ainda não estiver habilitado
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl_name);

        -- Remove políticas antigas para evitar conflitos
        EXECUTE format('DROP POLICY IF EXISTS "Permite acesso total para membros da empresa" ON public.%I;', tbl_name);

        -- Cria a política permissiva para membros da empresa
        -- Apenas se a tabela tiver a coluna 'empresa_id'
        IF EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
              AND table_name = tbl_name 
              AND column_name = 'empresa_id'
        ) THEN
            EXECUTE format('
                CREATE POLICY "Permite acesso total para membros da empresa"
                ON public.%I
                FOR ALL
                USING (empresa_id IN (SELECT private.get_empresa_id_for_user(auth.uid())))
                WITH CHECK (empresa_id IN (SELECT private.get_empresa_id_for_user(auth.uid())));
            ', tbl_name);
        END IF;
    END LOOP;
END;
$$;

-- Corrige o último warning de search_path na função de segurança
ALTER FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
SET search_path = public, private;
