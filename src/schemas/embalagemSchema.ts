import { z } from 'zod';
import { TipoEmbalagemProduto } from '../types';

// Helper para converter string (com vírgula) para número ou retornar null.
const stringToNumber = z.preprocess((val) => {
  if (val === null || val === undefined || val === '') return null;
  const strVal = String(val).replace(',', '.');
  const num = parseFloat(strVal);
  return isNaN(num) ? null : num;
}, z.number().nullable());

export const embalagemSchema = z.object({
  descricao: z.string().min(1, "Descrição é obrigatória."),
  tipo: z.nativeEnum(TipoEmbalagemProduto),
  peso: stringToNumber.optional(),
  largura: stringToNumber.optional(),
  altura: stringToNumber.optional(),
  comprimento: stringToNumber.optional(),
  diametro: stringToNumber.optional(),
});

export type EmbalagemFormData = z.infer<typeof embalagemSchema>;
