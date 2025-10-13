import React from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { useEmpresa } from '../../contexts/EmpresaContext';
import { PageLoader } from '../layout/PageLoader';
import { PrimeiraEmpresaForm } from '../settings/dados-empresa/PrimeiraEmpresaForm';

export const AppInitializer: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { status: authStatus } = useAuth();
  const { loading: empresaLoading, empresas, reloadEmpresas } = useEmpresa();

  if (authStatus === 'loading' || empresaLoading) {
    return <PageLoader />;
  }

  if (empresas.length === 0) {
    return <PrimeiraEmpresaForm onEmpresaCriada={reloadEmpresas} />;
  }

  // TODO: Adicionar seletor de empresa se empresas.length > 1

  return <>{children}</>;
};
