import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { EmpresaForm } from './EmpresaForm';
import { Empresa } from '../../../types';
import { useConfiguracoes } from '../../../contexts/ConfiguracoesContext';
import { Logo } from '../../ui/Logo';

interface PrimeiraEmpresaFormProps {
  onEmpresaCriada: () => void;
}

export const PrimeiraEmpresaForm: React.FC<PrimeiraEmpresaFormProps> = ({ onEmpresaCriada }) => {
  const { saveEmpresa } = useConfiguracoes();
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = async (empresaData: Partial<Empresa>, logoFile?: File | null) => {
    setIsSaving(true);
    try {
      await saveEmpresa(empresaData, logoFile);
      onEmpresaCriada();
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[#F4F7FE] p-4 relative overflow-hidden">
        <div className="absolute -top-1/4 -left-1/4 w-1/2 h-1/2 bg-blue-200/50 rounded-full filter blur-3xl opacity-50 animate-pulse"></div>
        <div className="absolute -bottom-1/4 -right-1/4 w-1/2 h-1/2 bg-purple-200/50 rounded-full filter blur-3xl opacity-50 animate-pulse animation-delay-4000"></div>

        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="w-full max-w-4xl z-10"
        >
            <div className="flex justify-center mb-6">
                <Logo />
            </div>
            <h2 className="text-2xl font-bold text-center text-gray-800 mb-2">Bem-vindo ao Revo ERP!</h2>
            <p className="text-center text-gray-600 mb-8">Para começar, precisamos dos dados da sua primeira empresa.</p>
            <EmpresaForm 
                onSave={handleSave} 
                onCancel={() => {}} 
                loading={isSaving} 
            />
        </motion.div>
    </div>
  );
};
