import React, { useState, useMemo } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, Edit2, Trash2, Filter, CheckCircle, XCircle } from 'lucide-react';
import { Header } from '../components/layout/Header';
import { GlassCard } from '../components/ui/GlassCard';
import { GlassButton } from '../components/ui/GlassButton';
import { GlassInput } from '../components/ui/GlassInput';
import { Pagination } from '../components/ui/Pagination';
import { DataTable } from '../components/ui/DataTable';
import { useModalForm } from '../hooks/useModalForm';
import { Servico, SituacaoServico } from '../types';
import { useCrud } from '../hooks/useCrud';
import { ServicoForm } from '../components/servicos/ServicoForm';
import { useEmpresa } from '../contexts/EmpresaContext';
import { ServicoFormData } from '../schemas/servicoSchema';
import { useConfirmationStore } from '../stores/useConfirmationStore';

export const Servicos: React.FC = () => {
  const { 
    items: servicos, 
    loading, 
    error, 
    createItem, 
    updateItem, 
    deleteItem,
    currentPage,
    totalPages,
    goToPage,
  } = useCrud<Servico>({ entityName: 'servico' });
  
  const { currentEmpresa } = useEmpresa();
  const { isFormOpen, editingItem, handleOpenCreateForm, handleOpenEditForm, handleCloseForm } = useModalForm<Servico>();
  const [isSaving, setIsSaving] = useState(false);
  const [filtro, setFiltro] = useState('');

  const servicosFiltrados = servicos.filter(serv =>
    serv.descricao.toLowerCase().includes(filtro.toLowerCase())
  );

  const handleSave = async (data: ServicoFormData) => {
    if (!currentEmpresa) return;
    setIsSaving(true);
    const dataToSave = { ...data, empresaId: currentEmpresa.id };
    try {
      if (editingItem) {
        await updateItem(editingItem.id, dataToSave);
      } else {
        await createItem(dataToSave as Omit<Servico, 'id' | 'createdAt' | 'updatedAt'>);
      }
      handleCloseForm();
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = (id: string) => {
    useConfirmationStore.getState().show(
      'Confirmar Exclusão',
      'Tem certeza que deseja excluir este serviço?',
      () => deleteItem(id)
    );
  };

  const formatCurrency = (value: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
  
  const columns = useMemo(() => [
    { header: 'Descrição', accessorKey: 'descricao', cell: (item: Servico) => <p className="font-medium text-gray-800">{item.descricao}</p> },
    { header: 'Preço', accessorKey: 'preco', cell: (item: Servico) => formatCurrency(item.preco || 0) },
    { header: 'Situação', accessorKey: 'situacao', cell: (item: Servico) => (
      item.situacao === SituacaoServico.ATIVO ? 
        <CheckCircle className="text-green-500 mx-auto" size={20} /> : 
        <XCircle className="text-red-500 mx-auto" size={20} />
    ), className: 'text-center' },
  ], []);

  return (
    <div>
      <Header title="Serviços" subtitle="Gerencie os serviços prestados pela sua empresa" />

      <GlassCard className="mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4 flex-1 min-w-[250px]">
            <GlassInput placeholder="Buscar por descrição..." value={filtro} onChange={(e) => setFiltro(e.target.value)} className="w-full max-w-md" />
            <GlassButton icon={Filter} variant="secondary">Filtros</GlassButton>
          </div>
          <GlassButton icon={Plus} onClick={handleOpenCreateForm}>Novo Serviço</GlassButton>
        </div>
      </GlassCard>

      <GlassCard>
        <DataTable
          data={servicosFiltrados}
          columns={columns}
          loading={loading && servicos.length === 0}
          error={error}
          entityName="Serviço"
          actions={(item) => (
            <div className="flex items-center gap-2">
              <GlassButton icon={Edit2} variant="secondary" size="sm" onClick={() => handleOpenEditForm(item)} />
              <GlassButton icon={Trash2} variant="danger" size="sm" onClick={() => handleDelete(item.id)} />
            </div>
          )}
        />
        <Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={goToPage} />
      </GlassCard>

      <AnimatePresence>
        {isFormOpen && (
          <ServicoForm
            servico={editingItem}
            onSave={handleSave}
            onCancel={handleCloseForm}
            loading={isSaving}
          />
        )}
      </AnimatePresence>
    </div>
  );
};
