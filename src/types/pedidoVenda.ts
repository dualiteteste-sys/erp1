import { IEntity } from './base';
import { ClienteFornecedor, Vendedor, Produto, Servico } from '.';

export enum StatusPedidoVenda {
  ABERTO = 'Aberto',
  ATENDIDO = 'Atendido',
  CANCELADO = 'Cancelado',
  FATURADO = 'Faturado',
}

export enum FretePorConta {
  CIF = 'CIF', // Remetente paga
  FOB = 'FOB', // Destinatário paga
}

export interface PedidoVendaItem extends IEntity {
  pedidoVendaId: string;
  produtoId?: string;
  servicoId?: string;
  descricao: string;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  produto?: Pick<Produto, 'id' | 'nome'>;
  servico?: Pick<Servico, 'id' | 'descricao'>;
}

export interface PedidoVenda extends IEntity {
  empresaId: string;
  numero: number;
  clienteId: string;
  vendedorId?: string;
  naturezaOperacao: string;
  status: StatusPedidoVenda;
  dataVenda: Date;
  dataPrevistaEntrega?: Date;
  valorTotal: number;
  desconto?: number;
  fretePorConta?: FretePorConta;
  valorFrete?: number;
  transportadoraId?: string;
  observacoes?: string;
  observacoesInternas?: string;
  
  // Relações
  cliente?: Pick<ClienteFornecedor, 'id' | 'nomeRazaoSocial'>;
  vendedor?: Pick<Vendedor, 'id' | 'nome'>;
  itens?: PedidoVendaItem[];
}
