import { z } from 'zod';
import { StatusPedidoVenda, FretePorConta } from '../types';

const numericNullable = z.preprocess((val) => {
  if (val === '' || val === null || val === undefined) return null;
  const strVal = String(val).replace(',', '.');
  const num = parseFloat(strVal);
  return isNaN(num) ? null : num;
}, z.number().nullable());

const currencyField = z.preprocess((val) => {
    if (val === null || val === undefined || val === '') return 0;
    if (typeof val === 'number') return val;
    const strVal = String(val).replace(/\./g, '').replace(',', '.');
    const num = parseFloat(strVal);
    return isNaN(num) ? 0 : num;
}, z.number());

const itemSchema = z.object({
  id: z.string().uuid().optional().nullable(),
  produtoId: z.string().uuid().optional().nullable(),
  servicoId: z.string().uuid().optional().nullable(),
  descricao: z.string().min(1, 'Descrição do item é obrigatória.'),
  quantidade: numericNullable.refine(val => val !== null && val > 0, { message: 'Quantidade deve ser maior que zero.' }),
  valorUnitario: currencyField.refine(val => val >= 0, { message: 'Valor unitário não pode ser negativo.' }),
  valorTotal: currencyField,
});

export const pedidoVendaSchema = z.object({
  id: z.string().uuid().optional().nullable(),
  naturezaOperacao: z.string().min(1, 'Natureza da operação é obrigatória.'),
  clienteId: z.string().uuid({ message: 'Cliente é obrigatório.' }),
  vendedorId: z.string().uuid().optional().nullable(),
  
  itens: z.array(itemSchema).min(1, 'Adicione pelo menos um item ao pedido.'),

  dataVenda: z.date().or(z.string()),
  dataPrevistaEntrega: z.date().or(z.string()).optional().nullable(),
  
  valorTotal: currencyField,
  desconto: currencyField.optional().nullable(),
  valorFrete: currencyField.optional().nullable(),
  
  status: z.nativeEnum(StatusPedidoVenda).default(StatusPedidoVenda.ABERTO),
  fretePorConta: z.nativeEnum(FretePorConta).optional().nullable(),
  transportadoraId: z.string().uuid().optional().nullable(),

  observacoes: z.string().optional().nullable(),
  observacoesInternas: z.string().optional().nullable(),
});

export type PedidoVendaFormData = z.infer<typeof pedidoVendaSchema>;
