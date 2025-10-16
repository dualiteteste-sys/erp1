/*
# [Function] is_member_of_empresa
Verifica se o usuário autenticado é membro de uma empresa específica.

## Query Description: [Esta função de segurança verifica a associação do usuário a uma empresa, consultando a tabela `empresa_usuarios`. É uma operação segura e não modifica dados, sendo essencial para as políticas de acesso do storage.]

## Metadata:
- Schema-Category: ["Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: [false]
- Reversible: [true]

## Structure Details:
- Function: is_member_of_empresa(p_empresa_id uuid)

## Security Implications:
- RLS Status: [N/A]
- Policy Changes: [No]
- Auth Requirements: [Authenticated User]

## Performance Impact:
- Indexes: [Relies on existing indexes on `empresa_usuarios` (empresa_id, user_id)]
- Triggers: [None]
- Estimated Impact: [Baixo. A consulta é rápida e específica.]
*/
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios
    WHERE empresa_id = p_empresa_id
    AND user_id = auth.uid()
  );
END;
$$;

-- Concede permissão de execução para usuários autenticados
GRANT EXECUTE ON FUNCTION public.is_member_of_empresa(uuid) TO authenticated;


/*
# [Bucket] Create produto-imagens bucket
Cria o bucket para armazenar as imagens dos produtos.

## Query Description: [Esta operação cria um novo bucket público no Supabase Storage chamado 'produto-imagens'. É uma operação segura e não afeta dados existentes. Se o bucket já existir, nada será feito.]

## Metadata:
- Schema-Category: ["Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: [false]
- Reversible: [false]

## Structure Details:
- Bucket: storage.buckets.produto-imagens

## Security Implications:
- RLS Status: [Enabled by default on storage.objects]
- Policy Changes: [No, policies will be added separately]
- Auth Requirements: [Admin/service_role]

## Performance Impact:
- Indexes: [None]
- Triggers: [None]
- Estimated Impact: [Nenhum impacto de performance na base de dados.]
*/
INSERT INTO storage.buckets (id, name, public)
VALUES ('produto-imagens', 'produto-imagens', true)
ON CONFLICT (id) DO NOTHING;


/*
# [RLS Policy] Allow public read access on product images
Permite que qualquer pessoa leia as imagens dos produtos.

## Query Description: [Esta política habilita o acesso de leitura público para todos os objetos no bucket 'produto-imagens'. Como o bucket já é público, esta política garante a consistência e clareza das permissões.]

## Metadata:
- Schema-Category: ["Security"]
- Impact-Level: ["Low"]
- Requires-Backup: [false]
- Reversible: [true]

## Structure Details:
- Table: storage.objects
- Policy: "Public read access for product images"

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [Yes]
- Auth Requirements: [None]

## Performance Impact:
- Indexes: [None]
- Triggers: [None]
- Estimated Impact: [Mínimo, RLS é otimizado pelo Supabase.]
*/
DROP POLICY IF EXISTS "Public read access for product images" ON storage.objects;
CREATE POLICY "Public read access for product images"
ON storage.objects FOR SELECT
USING ( bucket_id = 'produto-imagens' );


/*
# [RLS Policy] Allow authenticated inserts on product images
Permite que usuários autenticados e membros da empresa façam upload de imagens.

## Query Description: [Esta política de segurança permite que um usuário autenticado insira (faça upload) de um objeto no bucket 'produto-imagens' somente se ele for um membro da empresa correspondente ao `empresa_id` no caminho do arquivo (ex: `empresa_id/produto_id/file.png`).]

## Metadata:
- Schema-Category: ["Security"]
- Impact-Level: ["Medium"]
- Requires-Backup: [false]
- Reversible: [true]

## Structure Details:
- Table: storage.objects
- Policy: "Allow insert for company members"

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [Yes]
- Auth Requirements: [Authenticated User]

## Performance Impact:
- Indexes: [None]
- Triggers: [None]
- Estimated Impact: [Mínimo, a função `is_member_of_empresa` é otimizada.]
*/
DROP POLICY IF EXISTS "Allow insert for company members" ON storage.objects;
CREATE POLICY "Allow insert for company members"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'produto-imagens' AND
  public.is_member_of_empresa((storage.foldername(name))[1]::uuid)
);


/*
# [RLS Policy] Allow authenticated updates on product images
Permite que membros da empresa atualizem (substituam) suas próprias imagens.

## Query Description: [Esta política de segurança permite que um usuário autenticado atualize um objeto no bucket 'produto-imagens' somente se ele for um membro da empresa correspondente ao `empresa_id` no caminho do arquivo.]

## Metadata:
- Schema-Category: ["Security"]
- Impact-Level: ["Medium"]
- Requires-Backup: [false]
- Reversible: [true]

## Structure Details:
- Table: storage.objects
- Policy: "Allow update for company members"

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [Yes]
- Auth Requirements: [Authenticated User]

## Performance Impact:
- Indexes: [None]
- Triggers: [None]
- Estimated Impact: [Mínimo.]
*/
DROP POLICY IF EXISTS "Allow update for company members" ON storage.objects;
CREATE POLICY "Allow update for company members"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'produto-imagens' AND
  public.is_member_of_empresa((storage.foldername(name))[1]::uuid)
)
WITH CHECK (
  bucket_id = 'produto-imagens' AND
  public.is_member_of_empresa((storage.foldername(name))[1]::uuid)
);


/*
# [RLS Policy] Allow authenticated deletes on product images
Permite que membros da empresa deletem suas próprias imagens.

## Query Description: [Esta política de segurança permite que um usuário autenticado delete um objeto no bucket 'produto-imagens' somente se ele for um membro da empresa correspondente ao `empresa_id` no caminho do arquivo.]

## Metadata:
- Schema-Category: ["Security"]
- Impact-Level: ["High"]
- Requires-Backup: [false]
- Reversible: [true]

## Structure Details:
- Table: storage.objects
- Policy: "Allow delete for company members"

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [Yes]
- Auth Requirements: [Authenticated User]

## Performance Impact:
- Indexes: [None]
- Triggers: [None]
- Estimated Impact: [Mínimo.]
*/
DROP POLICY IF EXISTS "Allow delete for company members" ON storage.objects;
CREATE POLICY "Allow delete for company members"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'produto-imagens' AND
  public.is_member_of_empresa((storage.foldername(name))[1]::uuid)
);
