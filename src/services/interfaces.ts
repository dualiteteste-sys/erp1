import {
  ClienteFornecedor, Produto, ProdutoImagem, Embalagem, Papel, CategoriaFinanceira, FormaPagamento, Servico, Vendedor, Oportunidade, PedidoVenda
} from '../types';
import { Empresa } from '../types/empresa';
import { IRepository } from '../types/base';
import { DashboardStats, FaturamentoMensal } from '../types/dashboard';

// --- REPOSITORIES ---

export interface IConfiguracoesRepository extends IRepository<Empresa> {
  findFirst(): Promise<Empresa | null>;
  uploadLogo(file: File): Promise<string>;
  create(data: Partial<Empresa>, userId: string): Promise<Empresa>;
}

export interface IClienteRepository extends IRepository<ClienteFornecedor> {
  search(empresaId: string, query: string, type?: 'cliente' | 'fornecedor'): Promise<Pick<ClienteFornecedor, 'id' | 'nomeRazaoSocial'>[]>;
  uploadAnexo(empresaId: string, clienteId: string, file: File): Promise<string>;
  deleteAnexo(anexoId: string, filePath: string): Promise<void>;
  supabase: any;
}
export interface IProdutoRepository extends IRepository<Produto> {
  search(empresaId: string, query: string): Promise<Pick<Produto, 'id' | 'nome' | 'precoVenda' | 'codigo' | 'unidade' | 'custoMedio'>[]>;
  uploadImagem(empresaId: string, produtoId: string, file: File): Promise<string>;
  deleteImagem(imagemId: string, filePath: string): Promise<void>;
  supabase: any;
}
export interface IEmbalagemRepository extends IRepository<Embalagem> {}
export interface IServicoRepository extends IRepository<Servico> {}
export interface IVendedorRepository extends IRepository<Vendedor> {
  checkEmailExists(empresaId: string, email: string, vendedorId?: string): Promise<boolean>;
}
export interface IDashboardRepository {
    getDashboardStats(empresaId: string): Promise<DashboardStats>;
    getFaturamentoMensal(empresaId: string): Promise<FaturamentoMensal[]>;
}
export interface IPapelRepository extends IRepository<Papel> {
  setPermissions(papelId: string, permissionIds: string[]): Promise<void>;
}
export interface ICategoriaFinanceiraRepository extends IRepository<CategoriaFinanceira> {}
export interface IFormaPagamentoRepository extends IRepository<FormaPagamento> {}
export interface ICrmRepository extends IRepository<Oportunidade> {}
export interface IPedidoVendaRepository extends IRepository<PedidoVenda> {
  searchProdutosEServicos(empresaId: string, query: string): Promise<any[]>;
}

// --- SERVICES ---

export interface IConfiguracoesService {
  getEmpresaData(): Promise<Empresa | null>;
  saveEmpresaData(data: Partial<Empresa>, logoFile?: File | null, userId?: string): Promise<Empresa>;
  getAll(options?: { page?: number; pageSize?: number }): Promise<{ data: Empresa[]; count: number }>;
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
export interface IVendedorService extends IRepository<Vendedor> {
  checkEmailExists(empresaId: string, email: string, vendedorId?: string): Promise<boolean>;
}
export interface IDashboardService {
    getDashboardStats(empresaId: string): Promise<DashboardStats>;
    getFaturamentoMensal(empresaId: string): Promise<FaturamentoMensal[]>;
}
export interface IPapelService extends IRepository<Papel> {
  setPermissions(papelId: string, permissionIds: string[]): Promise<void>;
}
export interface ICategoriaFinanceiraService extends IRepository<CategoriaFinanceira> {}
export interface IFormaPagamentoService extends IRepository<FormaPagamento> {}
export interface ICrmService extends IRepository<Oportunidade> {}
export interface IPedidoVendaService extends IRepository<PedidoVenda> {
  searchProdutosEServicos(empresaId: string, query: string): Promise<any[]>;
}
