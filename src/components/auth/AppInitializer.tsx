import React from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { useEmpresa } from '../../contexts/EmpresaContext';
import { PageLoader } from '../layout/PageLoader';
import { PrimeiraEmpresaForm } from '../settings/dados-empresa/PrimeiraEmpresaForm';
import { GlassCard } from '../ui/GlassCard';
import { AlertTriangle, RefreshCw } from 'lucide-react';
import { GlassButton } from '../ui/GlassButton';

export const AppInitializer: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { status: authStatus } = useAuth();
  const { loading: empresaLoading, empresas, reloadEmpresas, error: empresaError } = useEmpresa();

  if (empresaError) {
    return (
      <div className="flex items-center justify-center h-screen p-4">
        <GlassCard className="text-center p-8 max-w-lg">
          <AlertTriangle className="mx-auto text-red-500 mb-4" size={48} />
          <h2 className="text-xl font-bold text-gray-800 mb-2">Falha na Conexão</h2>
          <p className="text-gray-600 mb-6">{empresaError}</p>
          <GlassButton onClick={reloadEmpresas} icon={RefreshCw}>
            Tentar Novamente
          </GlassButton>
        </GlassCard>
      </div>
    );
  }

  if (authStatus === 'loading' || empresaLoading) {
    return <PageLoader />;
  }

  if (empresas.length === 0) {
    return <PrimeiraEmpresaForm onEmpresaCriada={reloadEmpresas} />;
  }

  return <>{children}</>;
};
