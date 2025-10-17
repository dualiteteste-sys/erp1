-- Habilita RLS em todas as tabelas necessárias e aplica as políticas
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        -- Remove políticas antigas para evitar conflitos
        EXECUTE 'DROP POLICY IF EXISTS "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(table_name);

        -- Aplica a nova política
        IF table_name = 'empresas' THEN
             EXECUTE 'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.empresas FOR ALL USING (id IN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = auth.uid()));';
        ELSE
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = table_name AND column_name = 'empresa_id') THEN
                EXECUTE 'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(table_name) || ' FOR ALL USING (empresa_id IN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = auth.uid()));';
            END IF;
        END IF;
    END LOOP;
END $$;

-- Corrige o último aviso de segurança pendente
ALTER FUNCTION private.is_member_of_empresa(uuid, uuid) SET search_path = public;
