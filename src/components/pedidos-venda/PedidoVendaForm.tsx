import React, { useState, useMemo, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { motion, AnimatePresence } from 'framer-motion';
import { Info, ShoppingBag, Truck, CreditCard, FileText } from 'lucide-react';

import { PedidoVenda, StatusPedidoVenda } from '../../types';
import { PedidoVendaFormData, pedidoVendaSchema } from '../../schemas/pedidoVendaSchema';
import { GenericForm } from '../ui/GenericForm';
import { DadosGeraisTab } from './form/DadosGeraisTab';
import { ItensTab } from './form/ItensTab';

interface PedidoVendaFormProps {
  pedido?: Partial<PedidoVenda>;
  onSave: (data: PedidoVendaFormData) => void;
  onCancel: () => void;
  loading?: boolean;
}

const getInitialData = (pv?: Partial<PedidoVenda>): Partial<PedidoVendaFormData> => ({
  id: pv?.id,
  naturezaOperacao: pv?.naturezaOperacao || 'Venda de Mercadoria',
  clienteId: pv?.clienteId || '',
  vendedorId: pv?.vendedorId || undefined,
  dataVenda: pv?.dataVenda ? new Date(pv.dataVenda) : new Date(),
  dataPrevistaEntrega: pv?.dataPrevistaEntrega ? new Date(pv.dataPrevistaEntrega) : undefined,
  status: pv?.status || StatusPedidoVenda.ABERTO,
  valorTotal: pv?.valorTotal || 0,
  desconto: pv?.desconto || 0,
  valorFrete: pv?.valorFrete || 0,
  fretePorConta: pv?.fretePorConta || undefined,
  transportadoraId: pv?.transportadoraId || undefined,
  observacoes: pv?.observacoes || '',
  observacoesInternas: pv?.observacoesInternas || '',
  itens: pv?.itens?.map(item => ({
    id: item.id,
    produtoId: item.produtoId,
    servicoId: item.servicoId,
    descricao: item.descricao,
    quantidade: item.quantidade,
    valorUnitario: item.valorUnitario,
    valorTotal: item.valorTotal,
  })) || [],
});

export const PedidoVendaForm: React.FC<PedidoVendaFormProps> = ({ pedido, onSave, onCancel, loading }) => {
  const [activeTab, setActiveTab] = useState('dadosGerais');

  const form = useForm<PedidoVendaFormData>({
    resolver: zodResolver(pedidoVendaSchema),
    defaultValues: getInitialData(pedido),
  });

  const { control, handleSubmit, register, watch, setValue, formState: { errors } } = form;

  useEffect(() => {
    form.reset(getInitialData(pedido));
  }, [pedido, form]);

  const tabs = useMemo(() => [
    { id: 'dadosGerais', label: 'Dados Gerais', icon: Info },
    { id: 'itens', label: 'Itens', icon: ShoppingBag },
    { id: 'transporte', label: 'Transporte', icon: Truck },
    { id: 'pagamento', label: 'Pagamento', icon: CreditCard },
    { id: 'observacoes', label: 'Observações', icon: FileText },
  ], []);

  const renderTabContent = () => {
    switch (activeTab) {
      case 'dadosGerais':
        return <DadosGeraisTab control={control} errors={errors} pedido={pedido} />;
      case 'itens':
        return <ItensTab control={control} setValue={setValue} watch={watch} />;
      case 'observacoes':
        return (
          <div className="space-y-4">
            <textarea {...register('observacoes')} className="glass-input w-full h-32" placeholder="Observações para o cliente..." />
            <textarea {...register('observacoesInternas')} className="glass-input w-full h-32" placeholder="Observações internas (não aparecem na impressão)..." />
          </div>
        );
      default:
        return <div className="text-center p-8 text-gray-500">Módulo em desenvolvimento.</div>;
    }
  };

  return (
    <GenericForm
      title={pedido?.id ? `Editar Pedido #${pedido.numero}` : 'Novo Pedido de Venda'}
      onSave={handleSubmit(onSave)}
      onCancel={onCancel}
      loading={loading}
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
