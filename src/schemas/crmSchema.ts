import { z } from 'zod';
import { CrmEtapaFunil, CrmStatusOportunidade } from '../types';

const numericNullable = z.preprocess((val) => {
  if (val === '' || val === null || val === undefined) return null;
  const strVal = String(val).replace(',', '.');
  const num = parseFloat(strVal);
  return isNaN(num) ? null : num;
}, z.number().nullable());

const currencyField = z.preprocess((val) => {
    if (val === null || val === undefined || val === '') return null;
    if (typeof val === 'number') return val;
    const strVal = String(val).replace(/\./g, '').replace(',', '.');
    const num = parseFloat(strVal);
    return isNaN(num) ? null : num;
}, z.number().nullable());


const itemSchema = z.object({
  id: z.string().uuid().optional().nullable(),
  produtoId: z.string().uuid().optional().nullable(),
  servicoId: z.string().uuid().optional().nullable(),
  descricao: z.string().min(1, 'Descrição do item é obrigatória.'),
  quantidade: numericNullable.refine(val => val !== null && val > 0, { message: 'Quantidade deve ser maior que zero.' }),
  valorUnitario: currencyField.refine(val => val !== null && val >= 0, { message: 'Valor unitário não pode ser negativo.' }),
});

export const oportunidadeSchema = z.object({
  id: z.string().uuid().optional().nullable(),
  titulo: z.string().min(3, 'O título deve ter no mínimo 3 caracteres.'),
  clienteId: z.string().uuid({ message: 'Cliente é obrigatório.' }),
  vendedorId: z.string().uuid().optional().nullable(),
  valor: currencyField.refine(val => val !== null && val >= 0, { message: 'O valor da oportunidade é obrigatório.' }),
  etapaFunil: z.nativeEnum(CrmEtapaFunil, { message: 'Etapa do funil é obrigatória.' }),
  status: z.nativeEnum(CrmStatusOportunidade, { message: 'Status é obrigatório.' }),
  dataFechamentoPrevista: z.date({ message: 'Data de fechamento prevista é obrigatória.' }),
  observacoes: z.string().optional().nullable(),
  itens: z.array(itemSchema).optional(),
});

export type OportunidadeFormData = z.infer<typeof oportunidadeSchema>;
