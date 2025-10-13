import React, { ReactNode } from 'react';
import { AuthProvider } from './AuthContext';
import { SidebarProvider } from './SidebarContext';
import { ConfiguracoesProvider } from './ConfiguracoesContext';
import { ServiceProvider } from './ServiceContext';
import { ProfileProvider } from './ProfileContext';
import { EmpresaProvider } from './EmpresaContext';

// A ordem é importante. Provedores que dependem de outros devem vir depois.
const providers = [
  AuthProvider,
  ServiceProvider,
  EmpresaProvider,
  ConfiguracoesProvider,
  ProfileProvider,
  SidebarProvider,
  // PdvProvider foi removido por ser parte de um módulo legado.
];

export const AppProviders: React.FC<{ children: ReactNode }> = ({ children }) => {
  return providers.reduceRight((acc, Provider) => {
    return <Provider>{acc}</Provider>;
  }, <>{children}</>);
};
