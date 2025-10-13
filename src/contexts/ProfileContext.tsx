import React, { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';
import { supabase } from '../lib/supabaseClient';
import { Perfil } from '../types';
import { useAuth } from './AuthContext';
import toast from 'react-hot-toast';
import { useEmpresa } from './EmpresaContext';

interface ProfileContextType {
  profile: Perfil | null;
  permissions: Set<string>;
  profileLoading: boolean;
  hasPermission: (permission: string) => boolean;
}

const ProfileContext = createContext<ProfileContextType | undefined>(undefined);

export const ProfileProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const { currentEmpresa } = useEmpresa();
  const [profile, setProfile] = useState<Perfil | null>(null);
  const [permissions, setPermissions] = useState<Set<string>>(new Set());
  const [profileLoading, setProfileLoading] = useState(true);

  const fetchProfileAndPermissions = useCallback(async (userId: string, empresaId: string) => {
    setProfileLoading(true);
    try {
      // 1. Constrói o perfil básico do usuário a partir dos dados de autenticação
      const profileData: Perfil = {
        id: user!.id,
        nomeCompleto: user!.user_metadata.fullName || user!.email,
        cpf: user!.user_metadata.cpf_cnpj,
        empresaId: empresaId,
        createdAt: new Date(user!.created_at),
        updatedAt: new Date(user!.updated_at || user!.created_at),
      };
      setProfile(profileData);

      // 2. Verifica se o usuário é membro da empresa
      const { data: empresaUserData, error: memberError } = await supabase
        .from('empresa_usuarios')
        .select('user_id')
        .eq('user_id', userId)
        .eq('empresa_id', empresaId)
        .single();
      
      if (memberError && memberError.code !== 'PGRST116') throw memberError;

      // 3. Define as permissões
      // Lógica simplificada para estabilização: Se for membro, concede permissões básicas.
      // A lógica complexa de papéis foi removida para evitar erros de "tabela não encontrada".
      const userPermissions = new Set<string>();
      if (user?.email === 'leandro@revo.tec.br') {
        // Super admin tem todas as permissões
        userPermissions.add('admin');
      } else if (empresaUserData) {
        // Se for membro, concede permissões para os módulos ativos
        userPermissions.add('dashboard.ler');
        userPermissions.add('clientes.ler');
        userPermissions.add('clientes.escrever');
        userPermissions.add('clientes.excluir');
        userPermissions.add('configuracoes.ler');
        userPermissions.add('configuracoes.escrever');
      }
      
      setPermissions(userPermissions);

    } catch (error) {
      console.error('Error fetching profile and permissions:', error);
      toast.error('Falha ao carregar permissões do usuário.');
      setProfile(null);
      setPermissions(new Set());
    } finally {
      setProfileLoading(false);
    }
  }, [user]);

  useEffect(() => {
    if (user && currentEmpresa) {
      fetchProfileAndPermissions(user.id, currentEmpresa.id);
    } else if (!user) {
      setProfile(null);
      setPermissions(new Set());
      setProfileLoading(false);
    }
  }, [user, currentEmpresa, fetchProfileAndPermissions]);

  const hasPermission = (permission: string) => {
    if (permissions.has('admin')) return true;
    return permissions.has(permission);
  };

  const value = {
    profile,
    permissions,
    profileLoading,
    hasPermission,
  };

  return (
    <ProfileContext.Provider value={value}>
      {children}
    </ProfileContext.Provider>
  );
};

export const useProfile = () => {
  const context = useContext(ProfileContext);
  if (context === undefined) {
    throw new Error('useProfile must be used within a ProfileProvider');
  }
  return context;
};
