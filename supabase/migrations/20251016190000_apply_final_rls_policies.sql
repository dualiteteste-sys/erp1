-- Passo 1: Cria a função de segurança essencial e corrige o último warning.
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.empresa_usuarios eu
    WHERE eu.user_id = p_user_id AND eu.empresa_id = p_empresa_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Passo 2: Aplica as políticas de segurança (RLS) em todas as tabelas relevantes.
DO $$
DECLARE
    v_table_name TEXT;
BEGIN
    -- Loop para tabelas com a coluna 'empresa_id'
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name IN (
            'clientes_fornecedores',
            'clientes_contatos',
            'clientes_anexos',
            'produtos',
            'produto_imagens',
            'produto_atributos',
            'produto_fornecedores',
            'embalagens',
            'servicos',
            'vendedores',
            'vendedores_contatos',
            'papeis',
            'papel_permissoes',
            'categorias_financeiras',
            'formas_pagamento'
        )
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Membros podem gerenciar dados da sua empresa" ON public.%I;', v_table_name);
        EXECUTE format(
            'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ' ||
            'ON public.%I FOR ALL ' ||
            'USING (private.is_member_of_empresa(auth.uid(), empresa_id));',
            v_table_name
        );
    END LOOP;

    -- Política especial para a tabela 'empresas'
    DROP POLICY IF EXISTS "Membros podem visualizar suas próprias empresas" ON public.empresas;
    CREATE POLICY "Membros podem visualizar suas próprias empresas"
    ON public.empresas FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.empresa_usuarios eu
        WHERE eu.empresa_id = empresas.id AND eu.user_id = auth.uid()
    ));

    -- Política especial para a tabela 'empresa_usuarios'
    DROP POLICY IF EXISTS "Usuários podem ver suas próprias associações" ON public.empresa_usuarios;
    CREATE POLICY "Usuários podem ver suas próprias associações"
    ON public.empresa_usuarios FOR SELECT
    USING (user_id = auth.uid());

END;
$$;
