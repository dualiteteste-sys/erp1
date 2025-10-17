-- Habilita a RLS em todas as tabelas do esquema 'public' que ainda não a possuem.
DO $$
DECLARE
    v_table_name TEXT;
BEGIN
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
    LOOP
        -- Verifica se a RLS já está habilitada para evitar erros
        IF NOT (SELECT relrowsecurity FROM pg_class WHERE relname = v_table_name AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public') LIMIT 1) THEN
            EXECUTE 'ALTER TABLE public.' || quote_ident(v_table_name) || ' ENABLE ROW LEVEL SECURITY;';
        END IF;
    END LOOP;
END $$;

-- Cria a função de verificação de membro da empresa no esquema 'private' para segurança.
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios eu
    WHERE eu.user_id = p_user_id AND eu.empresa_id = p_empresa_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Aplica as políticas de segurança em todas as tabelas relevantes.
DO $$
DECLARE
    v_table_name TEXT;
BEGIN
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name <> 'empresa_usuarios' -- Não aplicar a si mesma
    LOOP
        -- Remove a política antiga se existir, para evitar conflitos
        EXECUTE 'DROP POLICY IF EXISTS "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(v_table_name);

        -- Cria a nova política
        IF v_table_name = 'empresas' THEN
            -- Política especial para a tabela de empresas
            EXECUTE 'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.empresas FOR ALL USING (id IN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = auth.uid()));';
        ELSE
            -- Política padrão para as outras tabelas
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = v_table_name AND column_name = 'empresa_id') THEN
                EXECUTE 'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(v_table_name) || ' FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));';
            END IF;
        END IF;
    END LOOP;
END $$;
