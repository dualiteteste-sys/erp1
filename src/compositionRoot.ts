import { ServiceContainer } from './contexts/ServiceContext';
import { createClienteService } from './services/factories/clienteServiceFactory';
import { createProdutoService } from './services/factories/produtoServiceFactory';
import { createConfiguracoesService } from './services/factories/configuracoesServiceFactory';
import { createDashboardService } from './services/factories/dashboardServiceFactory';
import { createEmbalagemService } from './services/factories/embalagemServiceFactory';
import { createPapelService } from './services/factories/papelServiceFactory';
import { createCategoriaFinanceiraService } from './services/factories/categoriaFinanceiraServiceFactory';
import { createFormaPagamentoService } from './services/factories/formaPagamentoServiceFactory';
import { createServicoService } from './services/factories/servicoServiceFactory';
import { createVendedorService } from './services/factories/vendedorServiceFactory';

// Use a factory to create the service container.
// This ensures that all dependencies are injected correctly and consistently.
export const serviceContainer: Omit<ServiceContainer, 'user' | 'crm' | 'pedidoVenda'> = {
  cliente: createClienteService(),
  produto: createProdutoService(),
  embalagem: createEmbalagemService(),
  servico: createServicoService(),
  vendedor: createVendedorService(),
  configuracoes: createConfiguracoesService(),
  dashboard: createDashboardService(),
  papel: createPapelService(),
  categoriaFinanceira: createCategoriaFinanceiraService(),
  formaPagamento: createFormaPagamentoService(),
};
