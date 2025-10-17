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
  error: string | null;
  reloadEmpresas: () => void;
}

const EmpresaContext = createContext<EmpresaContextType | undefined>(undefined);

export const EmpresaProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const { user, status: authStatus } = useAuth();
  const [empresas, setEmpresas] = useState<Empresa[]>([]);
  const [currentEmpresa, setCurrentEmpresa] = useState<Empresa | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadEmpresas = useCallback(async () => {
    if (!user) {
      setLoading(false);
      setEmpresas([]);
      setCurrentEmpresa(null);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const { data, error: fetchError } = await supabase.from('empresas').select('*');

      if (fetchError) throw fetchError;

      const empresasCamel = snakeToCamel(data) as Empresa[];
      setEmpresas(empresasCamel);
      
      // Lógica mais segura para definir a empresa atual
      setCurrentEmpresa(current => {
        if (current && empresasCamel.some(e => e.id === current.id)) {
          return current; // Mantém a empresa atual se ela ainda estiver na lista
        }
        return empresasCamel[0] || null; // Caso contrário, seleciona a primeira ou nulo
      });

    } catch (err: any) {
      console.error('Erro ao buscar empresas:', err);
      setError('Não foi possível conectar ao banco de dados. Verifique sua conexão com a internet e as configurações de CORS no seu projeto Supabase.');
      setEmpresas([]);
    } finally {
      setLoading(false);
    }
  }, [user]); // A dependência correta é apenas o `user`

  useEffect(() => {
    if (authStatus === 'ready') {
        loadEmpresas();
    }
  }, [authStatus, loadEmpresas]);

  const reloadEmpresas = useCallback(() => {
    setCurrentEmpresa(null); // Força a re-seleção da empresa padrão
    loadEmpresas();
  }, [loadEmpresas]);

  const value = { empresas, currentEmpresa, setCurrentEmpresa, loading, error, reloadEmpresas };

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
