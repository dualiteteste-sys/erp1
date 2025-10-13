import {
  ClienteFornecedor, Produto, ProdutoImagem, Embalagem, Papel, CategoriaFinanceira, FormaPagamento, Servico
} from '../types';
import { Empresa } from '../types/empresa';
import { IRepository } from '../types/base';
import { DashboardStats, FaturamentoMensal } from '../types/dashboard';

// --- SERVICES ---

export interface IConfiguracoesService {
  getEmpresaData(): Promise<Empresa | null>;
  saveEmpresaData(data: Partial<Empresa>, logoFile?: File | null, userId?: string): Promise<Empresa>;
  getAll(empresaId: string, options?: { page?: number; pageSize?: number }): Promise<{ data: Empresa[]; count: number }>;
  findById(id: string): Promise<Empresa | null>;
  create(data: Partial<Empresa>, userId: string): Promise<Empresa>;
  update(id: string, data: Partial<Empresa>): Promise<Empresa>;
  delete(id: string): Promise<void>;
}

export interface IClienteService extends IRepository<ClienteFornecedor> {
  search(empresaId: string, query: string, type?: 'cliente' | 'fornecedor'): Promise<Pick<ClienteFornecedor, 'id' | 'nomeRazaoSocial'>[]>;
  uploadAnexo(empresaId: string, clienteId: string, file: File): Promise<any>;
  deleteAnexo(anexoId: string, filePath: string): Promise<void>;
  getAnexoPublicUrl(filePath: string): string;
}
export interface IProdutoService extends IRepository<Produto> {
  search(empresaId: string, query: string): Promise<Pick<Produto, 'id' | 'nome' | 'precoVenda' | 'codigo' | 'unidade' | 'custoMedio'>[]>;
  uploadImagem(empresaId: string, produtoId: string, file: File): Promise<ProdutoImagem>;
  deleteImagem(imagemId: string, filePath: string): Promise<void>;
  getImagemPublicUrl(filePath: string): string;
}
export interface IEmbalagemService extends IRepository<Embalagem> {}
export interface IServicoService extends IRepository<Servico> {}
export interface IDashboardService {
    getDashboardStats(empresaId: string): Promise<DashboardStats>;
    getFaturamentoMensal(empresaId: string): Promise<FaturamentoMensal[]>;
}
export interface IPapelService extends IRepository<Papel> {
  setPermissions(papelId: string, permissionIds: string[]): Promise<void>;
}
export interface ICategoriaFinanceiraService extends IRepository<CategoriaFinanceira> {}
export interface IFormaPagamentoService extends IRepository<FormaPagamento> {}
