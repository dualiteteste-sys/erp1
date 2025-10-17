-- Passo 1: Adicionar a coluna 'empresa_id' que faltava na tabela de imagens de produtos.
ALTER TABLE public.produto_imagens
ADD COLUMN IF NOT EXISTS empresa_id UUID;

-- Passo 2: Preencher a nova coluna 'empresa_id' com os dados corretos, buscando da tabela de produtos.
UPDATE public.produto_imagens pi
SET empresa_id = p.empresa_id
FROM public.produtos p
WHERE pi.produto_id = p.id AND pi.empresa_id IS NULL;

-- Passo 3: Tornar a coluna 'empresa_id' obrigatória (NOT NULL) agora que ela está preenchida.
ALTER TABLE public.produto_imagens
ALTER COLUMN empresa_id SET NOT NULL;

-- Passo 4: Adicionar a restrição de chave estrangeira para garantir a integridade dos dados.
ALTER TABLE public.produto_imagens
ADD CONSTRAINT fk_produto_imagens_empresa
FOREIGN KEY (empresa_id)
REFERENCES public.empresas(id)
ON DELETE CASCADE;

-- Passo 5: Recriar a função de segurança 'is_member_of_empresa' com a configuração de search_path correta.
-- Isso resolve o último warning de 'Function Search Path Mutable'.
DROP FUNCTION IF EXISTS private.is_member_of_empresa(uuid, uuid);
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios
    WHERE user_id = p_user_id AND empresa_id = p_empresa_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION private.is_member_of_empresa(uuid, uuid) SET search_path = public;

-- Passo 6: Aplicar as políticas de segurança (RLS) em todas as tabelas.
-- Isso resolve os 8 avisos de 'RLS Enabled No Policy'.
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public' 
        AND tablename IN (
            'clientes_fornecedores', 'clientes_contatos', 'clientes_anexos',
            'produtos', 'produto_imagens', 'produto_atributos', 'produto_fornecedores',
            'embalagens', 'servicos', 'vendedores', 'vendedores_contatos',
            'papeis', 'papel_permissoes'
        )
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Membros podem gerenciar dados da sua empresa" ON public.%I;', table_name);
        EXECUTE format('
            CREATE POLICY "Membros podem gerenciar dados da sua empresa"
            ON public.%I
            FOR ALL
            USING (private.is_member_of_empresa(auth.uid(), empresa_id));
        ', table_name);
    END LOOP;
END;
$$;
