import React, { useState, useMemo } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, Edit2, Trash2, Filter } from 'lucide-react';
import { Header } from '../components/layout/Header';
import { GlassCard } from '../components/ui/GlassCard';
import { GlassButton } from '../components/ui/GlassButton';
import { GlassInput } from '../components/ui/GlassInput';
import { Pagination } from '../components/ui/Pagination';
import { DataTable } from '../components/ui/DataTable';
import { useModalForm } from '../hooks/useModalForm';
import { Embalagem, TipoEmbalagemProduto } from '../types';
import { useCrud } from '../hooks/useCrud';
import { EmbalagemForm } from '../components/embalagens/EmbalagemForm';
import { useEmpresa } from '../contexts/EmpresaContext';
import { EmbalagemFormData } from '../schemas/embalagemSchema';
import { useConfirmationStore } from '../stores/useConfirmationStore';

export const Embalagens: React.FC = () => {
  const { 
    items: embalagens, 
    loading, 
    error, 
    createItem, 
    updateItem, 
    deleteItem,
    currentPage,
    totalPages,
    goToPage,
  } = useCrud<Embalagem>({ entityName: 'embalagem' });
  
  const { currentEmpresa } = useEmpresa();
  const { isFormOpen, editingItem, handleOpenCreateForm, handleOpenEditForm, handleCloseForm } = useModalForm<Embalagem>();
  const [isSaving, setIsSaving] = useState(false);
  const [filtro, setFiltro] = useState('');

  const embalagensFiltradas = embalagens.filter(emb =>
    emb.descricao.toLowerCase().includes(filtro.toLowerCase())
  );

  const handleSave = async (data: EmbalagemFormData) => {
    if (!currentEmpresa) return;
    setIsSaving(true);
    const dataToSave = { ...data, empresaId: currentEmpresa.id };
    try {
      if (editingItem) {
        await updateItem(editingItem.id, dataToSave);
      } else {
        await createItem(dataToSave as Omit<Embalagem, 'id' | 'createdAt' | 'updatedAt'>);
      }
      handleCloseForm();
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = (id: string) => {
    useConfirmationStore.getState().show(
      'Confirmar Exclusão',
      'Tem certeza que deseja excluir esta embalagem?',
      () => deleteItem(id)
    );
  };

  const formatDimensions = (item: Embalagem) => {
    const { tipo, largura, altura, comprimento, diametro } = item;
    const format = (n?: number) => n?.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    
    switch (tipo) {
      case TipoEmbalagemProduto.ROLO_CILINDRO:
        return `${format(comprimento)}cm x ${format(diametro)}cm (Ø)`;
      case TipoEmbalagemProduto.ENVELOPE:
        return `${format(largura)}cm x ${format(comprimento)}cm`;
      default:
        return `${format(largura)}cm x ${format(altura)}cm x ${format(comprimento)}cm`;
    }
  };
  
  const columns = useMemo(() => [
    { header: 'Descrição', accessorKey: 'descricao', cell: (item: Embalagem) => <p className="font-medium text-gray-800">{item.descricao}</p> },
    { header: 'Tipo', accessorKey: 'tipo' },
    { header: 'Dimensões', accessorKey: 'dimensoes', cell: (item: Embalagem) => formatDimensions(item) },
    { header: 'Peso', accessorKey: 'peso', cell: (item: Embalagem) => `${item.peso?.toLocaleString('pt-BR')} kg` },
  ], []);

  return (
    <div>
      <Header title="Embalagens" subtitle="Gerencie os tipos de embalagens para seus produtos" />

      <GlassCard className="mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4 flex-1 min-w-[250px]">
            <GlassInput placeholder="Buscar por descrição..." value={filtro} onChange={(e) => setFiltro(e.target.value)} className="w-full max-w-md" />
            <GlassButton icon={Filter} variant="secondary">Filtros</GlassButton>
          </div>
          <GlassButton icon={Plus} onClick={handleOpenCreateForm}>Nova Embalagem</GlassButton>
        </div>
      </GlassCard>

      <GlassCard>
        <DataTable
          data={embalagensFiltradas}
          columns={columns}
          loading={loading && embalagens.length === 0}
          error={error}
          entityName="Embalagem"
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
          <EmbalagemForm
            embalagem={editingItem}
            onSave={handleSave}
            onCancel={handleCloseForm}
            loading={isSaving}
          />
        )}
      </AnimatePresence>
    </div>
  );
};
