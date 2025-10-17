import React, { createContext, ReactNode } from 'react';
import { serviceContainer } from '../compositionRoot';
import { 
  IClienteService, IProdutoService, IEmbalagemService, 
  IConfiguracoesService, IDashboardService, IPapelService,
  ICategoriaFinanceiraService, IFormaPagamentoService, IServicoService, IVendedorService, ICrmService
} from '../services/interfaces';

export interface ServiceContainer {
  cliente: IClienteService;
  produto: IProdutoService;
  embalagem: IEmbalagemService;
  servico: IServicoService;
  vendedor: IVendedorService;
  configuracoes: IConfiguracoesService;
  dashboard: IDashboardService;
  papel: IPapelService;
  categoriaFinanceira: ICategoriaFinanceiraService;
  formaPagamento: IFormaPagamentoService;
  crm: ICrmService;
}

export const ServiceContext = createContext<Omit<ServiceContainer, 'user'>>(serviceContainer);

export const ServiceProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  return (
    <ServiceContext.Provider value={serviceContainer}>
      {children}
    </ServiceContext.Provider>
  );
};
