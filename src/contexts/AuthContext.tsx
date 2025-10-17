import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import type { Session, User } from '@supabase/supabase-js';

type AuthCtx = {
  status: 'loading' | 'ready';
  session: Session | null;
  user: User | null;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
};

const Ctx = createContext<AuthCtx | null>(null);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [status, setStatus] = useState<'loading' | 'ready'>('loading');
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    // O onAuthStateChange é a fonte única da verdade para o estado da sessão.
    // Ele é disparado uma vez no carregamento inicial com a sessão atual e, em seguida,
    // sempre que o estado de autenticação mudar (login, logout, refresh de token).
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      setStatus('ready'); // O primeiro evento que chega define o status de autenticação inicial.
    });

    return () => {
      subscription?.unsubscribe();
    };
  }, []); // Executa apenas uma vez, quando o componente é montado.

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) {
      console.error('Error signing out:', error);
    }
    // Limpa o estado manualmente como um fallback, embora o onAuthStateChange deva cuidar disso.
    setSession(null);
    setUser(null);
  };

  const value = useMemo(() => ({ status, session, user, signIn, signOut }), [status, session, user]);

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
};

export const useAuth = () => {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useAuth must be used within <AuthProvider>');
  return ctx;
};
