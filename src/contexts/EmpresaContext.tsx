import React, { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from './AuthContext';
import { Empresa } from '../types';
import { snakeToCamel } from '../lib/utils';

interface EmpresaContextType {
  empresas: Empresa[];
  currentEmpresa: Empresa | null;
  setCurrentEmpresa: (empresa: Empresa | null) => void;
  loading: boolean;
  reloadEmpresas: () => void;
}

const EmpresaContext = createContext<EmpresaContextType | undefined>(undefined);

export const EmpresaProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const { user, status: authStatus } = useAuth();
  const [empresas, setEmpresas] = useState<Empresa[]>([]);
  const [currentEmpresa, setCurrentEmpresa] = useState<Empresa | null>(null);
  const [loading, setLoading] = useState(true);

  const loadEmpresas = useCallback(async () => {
    if (!user) {
      setLoading(false);
      setEmpresas([]);
      setCurrentEmpresa(null);
      return;
    }

    setLoading(true);
    const { data, error } = await supabase.from('empresas').select('*');

    if (error) {
      console.error('Erro ao buscar empresas:', error);
      setEmpresas([]);
    } else {
      const empresasCamel = snakeToCamel(data) as Empresa[];
      setEmpresas(empresasCamel);
      if (empresasCamel.length > 0 && !currentEmpresa) {
        setCurrentEmpresa(empresasCamel[0]);
      }
    }
    setLoading(false);
  }, [user, currentEmpresa]);

  useEffect(() => {
    if (authStatus === 'ready') {
        loadEmpresas();
    }
  }, [user, authStatus, loadEmpresas]);

  const reloadEmpresas = useCallback(() => {
    // Força um reload ao resetar o estado e chamar loadEmpresas
    setCurrentEmpresa(null);
    loadEmpresas();
  }, [loadEmpresas]);

  const value = { empresas, currentEmpresa, setCurrentEmpresa, loading, reloadEmpresas };

  return (
    <EmpresaContext.Provider value={value}>
      {children}
    </EmpresaContext.Provider>
  );
};

export const useEmpresa = () => {
  const context = useContext(EmpresaContext);
  if (context === undefined) {
    throw new Error('useEmpresa must be used within an EmpresaProvider');
  }
  return context;
};
