import React, { useState, useEffect, useCallback } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { motion, AnimatePresence } from 'framer-motion';
import { Info, KeyRound, Percent, UserPlus } from 'lucide-react';
import toast from 'react-hot-toast';
import axios from 'axios';

import { GenericForm } from '../ui/GenericForm';
import { Vendedor } from '../../types';
import { VendedorFormData, vendedorSchema } from '../../schemas/vendedorSchema';
import { useService } from '../../hooks/useService';
import { useCep } from '../../hooks/useCep';
import { getInitialData } from './form/formUtils';

import { DadosGeraisTab } from './form/DadosGeraisTab';
import { ContatosAdicionaisTab } from './form/ContatosAdicionaisTab';
import { AcessoPermissoesTab } from './form/AcessoPermissoesTab';
import { ComissionamentoTab } from './form/ComissionamentoTab';
import { useEmpresa } from '../../contexts/EmpresaContext';

interface VendedorFormProps {
  vendedor?: Partial<Vendedor>;
  onSave: (data: VendedorFormData) => void;
  onCancel: () => void;
  loading: boolean;
}

export const VendedorForm: React.FC<VendedorFormProps> = ({ vendedor, onSave, onCancel, loading }) => {
  const vendedorService = useService('vendedor');
  const { currentEmpresa } = useEmpresa();
  const [activeTab, setActiveTab] = useState('dadosGerais');
  const [isCheckingEmail, setIsCheckingEmail] = useState(false);

  const form = useForm<VendedorFormData>({
    resolver: zodResolver(vendedorSchema),
    defaultValues: getInitialData(vendedor, currentEmpresa?.id),
  });

  const { control, handleSubmit, register, watch, setValue, reset, setError, clearErrors, formState: { errors } } = form;
  const { handleBuscaCep } = useCep(setValue);

  useEffect(() => {
    reset(getInitialData(vendedor, currentEmpresa?.id));
  }, [vendedor, currentEmpresa, reset]);
  
  const handleBuscaCnpj = useCallback(async (cnpj: string) => {
    const cleanCnpj = cnpj.replace(/\D/g, '');
    if (cleanCnpj.length !== 14) return;
    const toastId = toast.loading('Buscando dados do CNPJ...');
    try {
      const { data } = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${cleanCnpj}`);
      setValue('nome', data.razao_social || '', { shouldValidate: true });
      setValue('fantasia', data.nome_fantasia || '', { shouldValidate: true });
      await handleBuscaCep(data.cep || '');
      toast.success('Dados preenchidos com sucesso!', { id: toastId });
    } catch (error) {
      toast.error('Falha ao buscar dados do CNPJ.', { id: toastId });
    }
  }, [setValue, handleBuscaCep]);

  const handleEmailBlur = async (email: string) => {
    if (!email || !currentEmpresa?.id) return;
    setIsCheckingEmail(true);
    clearErrors('email');
    try {
      const exists = await vendedorService.checkEmailExists(currentEmpresa.id, email, vendedor?.id);
      if (exists) {
        setError('email', { type: 'manual', message: 'Este e-mail já está em uso.' });
        toast.error('Este e-mail já está em uso.');
      }
    } catch (err) {
      toast.error('Falha ao verificar o e-mail.');
    } finally {
      setIsCheckingEmail(false);
    }
  };

  const tabs = [
    { id: 'dadosGerais', label: 'Dados Gerais', icon: Info },
    { id: 'contatosAdicionais', label: 'Contatos Adicionais', icon: UserPlus },
    { id: 'acessoPermissoes', label: 'Acesso e Permissões', icon: KeyRound },
    { id: 'comissionamento', label: 'Comissionamento', icon: Percent },
  ];

  const renderTabContent = () => {
    switch (activeTab) {
      case 'dadosGerais':
        return <DadosGeraisTab control={control} register={register} watch={watch} errors={errors} onBuscaCnpj={handleBuscaCnpj} onEmailBlur={handleEmailBlur} onBuscaCep={handleBuscaCep} />;
      case 'contatosAdicionais':
        return <ContatosAdicionaisTab control={control} />;
      case 'acessoPermissoes':
        return <AcessoPermissoesTab control={control} register={register} setValue={setValue} errors={errors} vendedor={vendedor} />;
      case 'comissionamento':
        return <ComissionamentoTab control={control} register={register} watch={watch} />;
      default:
        return null;
    }
  };

  return (
    <GenericForm
      title={vendedor?.id ? 'Editar Vendedor' : 'Novo Vendedor'}
      onSave={handleSubmit(onSave)}
      onCancel={onCancel}
      loading={loading || isCheckingEmail}
      size="max-w-7xl"
    >
      <div className="px-8 pt-4 border-b border-white/30 -mt-8 -mx-8 mb-8">
        <div className="flex items-end -mb-px overflow-x-auto">
          {tabs.map(tab => (
            <button
              key={tab.id}
              type="button"
              onClick={() => setActiveTab(tab.id)}
              className={`flex-shrink-0 flex items-center gap-2 px-4 pt-3 pb-2 transition-colors duration-300 text-sm font-medium border-b-2
                ${activeTab === tab.id 
                  ? 'bg-glass-100 border-blue-600 text-blue-700 rounded-t-lg border-x border-t border-x-white/30 border-t-white/30' 
                  : 'border-transparent text-gray-600 hover:text-blue-600'
                }`}
            >
              <tab.icon size={16} />
              {tab.label}
            </button>
          ))}
        </div>
      </div>
      <AnimatePresence mode="wait">
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          transition={{ duration: 0.2 }}
        >
          {renderTabContent()}
        </motion.div>
      </AnimatePresence>
    </GenericForm>
  );
};
