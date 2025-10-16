/*
          # Add tamanho_bytes column to produto_imagens
          This migration adds the 'tamanho_bytes' column to the 'produto_imagens' table to store the size of the uploaded image file.

          ## Query Description: [This operation alters the 'produto_imagens' table to include a new column for file size. It is a non-destructive change and should not impact existing data.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - Table: produto_imagens
          - Column Added: tamanho_bytes (BIGINT)
          
          ## Security Implications:
          - RLS Status: [No Change]
          - Policy Changes: [No]
          - Auth Requirements: [None]
          
          ## Performance Impact:
          - Indexes: [None]
          - Triggers: [None]
          - Estimated Impact: [Negligible impact on performance.]
          */

ALTER TABLE public.produto_imagens
ADD COLUMN IF NOT EXISTS tamanho_bytes BIGINT;
