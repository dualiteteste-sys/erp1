import React, { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { PageLoader } from './components/layout/PageLoader';
import { AppProviders } from './contexts/AppProviders';
import { ProtectedRoute } from './components/auth/ProtectedRoute';
import { AppInitializer } from './components/auth/AppInitializer';
import { Login } from './pages/Login';
import { SignUp } from './pages/SignUp';
import MainLayout from './layouts/MainLayout';
import { ConfirmationModal } from './components/ui/ConfirmationModal';

const Dashboard = lazy(() => import('./pages/Dashboard').then(module => ({ default: module.Dashboard })));
const Clientes = lazy(() => import('./pages/Clientes').then(module => ({ default: module.Clientes })));
const Produtos = lazy(() => import('./pages/Produtos').then(module => ({ default: module.Produtos })));
const Embalagens = lazy(() => import('./pages/Embalagens').then(module => ({ default: module.Embalagens })));
const Servicos = lazy(() => import('./pages/Servicos').then(module => ({ default: module.Servicos })));
const Vendedores = lazy(() => import('./pages/Vendedores').then(module => ({ default: module.Vendedores })));
const EmDesenvolvimento = lazy(() => import('./pages/EmDesenvolvimento').then(module => ({ default: module.EmDesenvolvimento })));
const SettingsRoutes = lazy(() => import('./pages/configuracoes'));

function App() {
  return (
    <Router>
      <AppProviders>
        <div className="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 text-gray-800">
          <Toaster position="bottom-right" />
          <ConfirmationModal />
          <Suspense fallback={<PageLoader />}>
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route path="/signup" element={<SignUp />} />
              <Route path="/*" element={
                <ProtectedRoute>
                  <AppInitializer>
                    <MainLayout>
                      <Routes>
                          <Route path="/" element={<Navigate to="/dashboard" replace />} />
                          <Route path="/dashboard" element={<Dashboard />} />
                          
                          {/* Módulos Ativos */}
                          <Route path="/clientes" element={<Clientes />} />
                          <Route path="/produtos" element={<Produtos />} />
                          <Route path="/embalagens" element={<Embalagens />} />
                          <Route path="/servicos" element={<Servicos />} />
                          <Route path="/vendedores" element={<Vendedores />} />
                          <Route path="/configuracoes/*" element={<SettingsRoutes />} />

                          {/* Módulos em Desenvolvimento */}
                          <Route path="/cadastros/relatorios" element={<EmDesenvolvimento modulo="Relatórios de Cadastros" />} />
                          
                          <Route path="/ordens-compra" element={<EmDesenvolvimento modulo="Ordens de Compra" />} />
                          <Route path="/controle-estoque" element={<EmDesenvolvimento modulo="Controle de Estoque" />} />
                          <Route path="/notas-entrada" element={<EmDesenvolvimento modulo="Notas de Entrada" />} />
                          <Route path="/suprimentos/relatorios" element={<EmDesenvolvimento modulo="Relatórios de Suprimentos" />} />
                          
                          <Route path="/ordens-servico" element={<EmDesenvolvimento modulo="Ordens de Serviço" />} />
                          <Route path="/servicos/relatorios" element={<EmDesenvolvimento modulo="Relatórios de Serviços" />} />
                          <Route path="/notas-servico" element={<EmDesenvolvimento modulo="Notas de Serviço" />} />
                          <Route path="/servicos/cobrancas" element={<EmDesenvolvimento modulo="Cobranças de Serviços" />} />
                          
                          <Route path="/notas-fiscais" element={<EmDesenvolvimento modulo="Notas Fiscais" />} />
                          <Route path="/notas-fiscais/novo/:pedidoId" element={<EmDesenvolvimento modulo="Nova Fatura de Venda" />} />
                          <Route path="/expedicao" element={<EmDesenvolvimento modulo="Expedição" />} />
                          <Route path="/automacoes" element={<EmDesenvolvimento modulo="Painel de Automações" />} />
                          <Route path="/pdv" element={<EmDesenvolvimento modulo="PDV" />} />
                          <Route path="/propostas-comerciais" element={<EmDesenvolvimento modulo="Propostas Comerciais" />} />
                          <Route path="/comissoes" element={<EmDesenvolvimento modulo="Comissões" />} />
                          <Route path="/devolucao-venda" element={<EmDesenvolvimento modulo="Devolução de Venda" />} />
                          <Route path="/contratos" element={<EmDesenvolvimento modulo="Contratos" />} />
                          
                          <Route path="/caixa" element={<EmDesenvolvimento modulo="Caixa" />} />
                          <Route path="/contas-receber" element={<EmDesenvolvimento modulo="Contas a Receber" />} />
                          <Route path="/contas-pagar" element={<EmDesenvolvimento modulo="Contas a Pagar" />} />
                          <Route path="/cobrancas-bancarias" element={<EmDesenvolvimento modulo="Cobranças Bancárias" />} />
                          <Route path="/extrato-bancario" element={<EmDesenvolvimento modulo="Extrato Bancário" />} />
                          <Route path="/financeiro/relatorios" element={<EmDesenvolvimento modulo="Relatórios Financeiros" />} />
                          
                          <Route path="/suporte" element={<EmDesenvolvimento modulo="Suporte" />} />
                          
                          <Route path="*" element={<Navigate to="/dashboard" replace />} />
                      </Routes>
                    </MainLayout>
                  </AppInitializer>
                </ProtectedRoute>
              } />
            </Routes>
          </Suspense>
        </div>
      </AppProviders>
    </Router>
  );
}

export default App;
