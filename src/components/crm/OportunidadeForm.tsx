import React, { useState, useMemo, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { motion, AnimatePresence } from 'framer-motion';
import { Info, ShoppingBag, FileText } from 'lucide-react';

import { Oportunidade, CrmEtapaFunil, CrmStatusOportunidade } from '../../types';
import { OportunidadeFormData, oportunidadeSchema } from '../../schemas/crmSchema';
import { useEmpresa } from '../../contexts/EmpresaContext';
import { GenericForm } from '../ui/GenericForm';
import { DadosGeraisTab } from './form/DadosGeraisTab';
import { ItensTab } from './form/ItensTab';
import { ObservacoesTab } from './form/ObservacoesTab';

interface OportunidadeFormProps {
  oportunidade?: Partial<Oportunidade>;
  onSave: (data: OportunidadeFormData) => void;
  onCancel: () => void;
  loading?: boolean;
}

const getInitialData = (op?: Partial<Oportunidade>): Partial<OportunidadeFormData> => ({
  id: op?.id,
  titulo: op?.titulo || '',
  clienteId: op?.clienteId || '',
  vendedorId: op?.vendedorId || undefined,
  valor: op?.valor || 0,
  etapaFunil: op?.etapaFunil || CrmEtapaFunil.PROSPECCAO,
  status: op?.status || CrmStatusOportunidade.EM_ABERTO,
  dataFechamentoPrevista: op?.dataFechamentoPrevista ? new Date(op.dataFechamentoPrevista) : new Date(),
  observacoes: op?.observacoes || '',
  itens: op?.itens?.map(item => ({
    id: item.id,
    produtoId: item.produtoId,
    servicoId: item.servicoId,
    descricao: item.descricao,
    quantidade: item.quantidade,
    valorUnitario: item.valorUnitario,
  })) || [],
});

export const OportunidadeForm: React.FC<OportunidadeFormProps> = ({ oportunidade, onSave, onCancel, loading }) => {
  const { currentEmpresa } = useEmpresa();
  const [activeTab, setActiveTab] = useState('dadosGerais');

  const form = useForm<OportunidadeFormData>({
    resolver: zodResolver(oportunidadeSchema),
    defaultValues: getInitialData(oportunidade),
  });

  const { control, handleSubmit, register, watch, setValue, formState: { errors } } = form;

  useEffect(() => {
    form.reset(getInitialData(oportunidade));
  }, [oportunidade, form]);

  const tabs = useMemo(() => [
    { id: 'dadosGerais', label: 'Dados Gerais', icon: Info },
    { id: 'itens', label: 'Itens', icon: ShoppingBag },
    { id: 'observacoes', label: 'Observações', icon: FileText },
  ], []);

  const renderTabContent = () => {
    switch (activeTab) {
      case 'dadosGerais':
        return <DadosGeraisTab control={control} errors={errors} oportunidade={oportunidade} />;
      case 'itens':
        return <ItensTab control={control} setValue={setValue} watch={watch} />;
      case 'observacoes':
        return <ObservacoesTab register={register} />;
      default:
        return null;
    }
  };

  return (
    <GenericForm
      title={oportunidade?.id ? 'Editar Oportunidade' : 'Nova Oportunidade'}
      onSave={handleSubmit(onSave)}
      onCancel={onCancel}
      loading={loading}
      size="max-w-6xl"
    >
      <div className="px-8 pt-4 border-b border-white/30 -mt-8 -mx-8 mb-8">
        <div className="flex items-end -mb-px">
          {tabs.map(tab => (
            <button
              key={tab.id}
              type="button"
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-4 pt-3 pb-2 transition-colors duration-300 text-sm font-medium border-b-2
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
