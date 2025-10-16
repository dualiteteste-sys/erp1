import { IEntity } from './base';

export enum SituacaoServico {
    ATIVO = 'Ativo',
    INATIVO = 'Inativo'
}

export interface Servico extends IEntity {
  empresaId: string;
  descricao: string;
  preco: number;
  situacao: SituacaoServico;
  codigo?: string;
  unidade?: string;
  codigoServico?: string;
  nbs?: string;
  descricaoComplementar?: string;
  observacoes?: string;
}
