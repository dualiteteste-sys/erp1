/*
# [ADD_FILENAME_TO_PRODUCT_IMAGES]
Adiciona a coluna 'nome_arquivo' à tabela 'produto_imagens' para armazenar o nome original do arquivo de imagem.

## Query Description: [Esta operação adiciona uma nova coluna de texto à tabela que armazena as imagens dos produtos. Não há risco de perda de dados, pois é uma adição não destrutiva. A coluna é necessária para que o sistema possa salvar e exibir corretamente o nome dos arquivos de imagem enviados.]

## Metadata:
- Schema-Category: ["Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: [false]
- Reversible: [true]

## Structure Details:
- Tabela afetada: public.produto_imagens
- Coluna adicionada: nome_arquivo (TEXT)

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [No]
- Auth Requirements: [N/A]

## Performance Impact:
- Indexes: [None]
- Triggers: [None]
- Estimated Impact: [Nenhum impacto de performance esperado, pois é uma adição de coluna sem indexação imediata.]
*/

ALTER TABLE public.produto_imagens
ADD COLUMN nome_arquivo TEXT;
