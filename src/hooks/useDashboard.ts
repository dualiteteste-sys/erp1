import { useState, useEffect, useCallback } from 'react';
import { useService } from './useService';
import { useEmpresa } from '../contexts/EmpresaContext';
import { DashboardStats, FaturamentoMensal } from '../types';
import toast from 'react-hot-toast';

export const useDashboard = () => {
  const dashboardService = useService('dashboard');
  const { currentEmpresa } = useEmpresa();

  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [faturamentoMensal, setFaturamentoMensal] = useState<FaturamentoMensal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadDashboardData = useCallback(async (empresaId: string) => {
    setLoading(true);
    setError(null);
    try {
      const [statsData, faturamentoData] = await Promise.all([
        dashboardService.getDashboardStats(empresaId),
        dashboardService.getFaturamentoMensal(empresaId),
      ]);
      setStats(statsData);
      setFaturamentoMensal(faturamentoData);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Erro ao carregar dados do dashboard';
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  }, [dashboardService]);

  useEffect(() => {
    if (currentEmpresa?.id) {
      loadDashboardData(currentEmpresa.id);
    } else {
      setLoading(false);
    }
  }, [currentEmpresa, loadDashboardData]);

  return { stats, faturamentoMensal, loading, error };
};
