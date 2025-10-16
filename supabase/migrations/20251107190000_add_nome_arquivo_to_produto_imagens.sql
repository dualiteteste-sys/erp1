/*
# [Structural] Adiciona a coluna `nome_arquivo` à tabela `produto_imagens`
Este script adiciona a coluna `nome_arquivo` à tabela `produto_imagens` para corrigir um erro de "coluna não existente" que ocorre ao fazer upload de imagens de produtos. A coluna armazenará o nome original do arquivo enviado, alinhando o banco de dados com o código da aplicação.

## Query Description:
- **Impacto nos Dados:** Nenhum dado existente será perdido. A nova coluna `nome_arquivo` será preenchida com `NULL` para os registros existentes.
- **Riscos:** Baixo. A operação é aditiva e não destrutiva.
- **Precauções:** Nenhuma precaução especial é necessária.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true (A coluna pode ser removida com `ALTER TABLE public.produto_imagens DROP COLUMN nome_arquivo;`)

## Structure Details:
- Tabela Afetada: `public.produto_imagens`
- Coluna Adicionada: `nome_arquivo` (TEXT)

## Security Implications:
- RLS Status: A política de RLS existente para a tabela não é afetada.
- Policy Changes: Não
- Auth Requirements: Acesso de administrador para alterar a tabela.

## Performance Impact:
- Indexes: Nenhum índice novo é adicionado.
- Triggers: Nenhum trigger novo é adicionado.
- Estimated Impact: Mínimo. A adição de uma coluna de texto pode aumentar ligeiramente o tamanho da tabela ao longo do tempo.
*/
ALTER TABLE public.produto_imagens
ADD COLUMN nome_arquivo TEXT;
