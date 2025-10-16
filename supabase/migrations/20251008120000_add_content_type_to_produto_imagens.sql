/*
# [ADD_CONTENT_TYPE_TO_PRODUTO_IMAGENS]
Adiciona a coluna `content_type` à tabela `produto_imagens` para armazenar o tipo MIME do arquivo.

## Query Description:
Esta operação adiciona uma nova coluna à tabela `produto_imagens`. Não há risco de perda de dados existentes. A coluna será preenchida com `NULL` para os registros existentes.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true

## Structure Details:
- Tabela afetada: `produto_imagens`
- Coluna adicionada: `content_type` (TEXT)

## Security Implications:
- RLS Status: N/A
- Policy Changes: No
- Auth Requirements: N/A

## Performance Impact:
- Indexes: Nenhum
- Triggers: Nenhum
- Estimated Impact: Baixo. A operação é rápida em tabelas de tamanho moderado.
*/
ALTER TABLE public.produto_imagens
ADD COLUMN content_type TEXT;
