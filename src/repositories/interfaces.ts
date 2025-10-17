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
