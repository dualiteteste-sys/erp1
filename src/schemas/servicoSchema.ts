import { z } from 'zod';
import { SituacaoServico } from '../types';

export const servicoSchema = z.object({
  descricao: z.string().min(1, "Descrição é obrigatória."),
  preco: z.preprocess((val) => {
    if (typeof val === 'string') {
      const num = parseFloat(val.replace('.', '').replace(',', '.'));
      return isNaN(num) ? 0 : num;
    }
    return val;
  }, z.number().min(0, 'O preço não pode ser negativo.')),
  situacao: z.nativeEnum(SituacaoServico).default(SituacaoServico.ATIVO),
});

export type ServicoFormData = z.infer<typeof servicoSchema>;
