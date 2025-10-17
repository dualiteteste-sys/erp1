import React, { useState, useMemo, useCallback } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, Edit2, Trash2, Loader2, LayoutGrid, List } from 'lucide-react';
import toast from 'react-hot-toast';
import { Header } from '../components/layout/Header';
import { GlassCard } from '../components/ui/GlassCard';
import { GlassButton } from '../components/ui/GlassButton';
import { useModalForm } from '../hooks/useModalForm';
import { Oportunidade, CrmEtapaFunil } from '../types';
import { useCrud } from '../hooks/useCrud';
import { useEmpresa } from '../contexts/EmpresaContext';
import { useService } from '../hooks/useService';
import { useConfirmationStore } from '../stores/useConfirmationStore';
import { OportunidadeFormData } from '../schemas/crmSchema';
import { OportunidadeForm } from '../components/crm/OportunidadeForm';
import { KanbanBoard } from '../components/crm/KanbanBoard';

const FUNIL_STAGES_ORDER: CrmEtapaFunil[] = [
  CrmEtapaFunil.PROSPECCAO,
  CrmEtapaFunil.QUALIFICACAO,
  CrmEtapaFunil.PROPOSTA,
  CrmEtapaFunil.NEGOCIACAO,
  CrmEtapaFunil.FECHAMENTO,
];

export const Crm: React.FC = () => {
  const crmService = useService('crm');
  const { 
    items: oportunidades, 
    loading, 
    error, 
    createItem, 
    updateItem, 
    deleteItem,
    loadItems,
  } = useCrud<Oportunidade>({ entityName: 'crm', initialPageSize: 1000 }); // Fetch all for Kanban
  
  const { currentEmpresa } = useEmpresa();
  const { isFormOpen, editingItem, handleOpenCreateForm, handleOpenEditForm, handleCloseForm } = useModalForm<Oportunidade>();
  
  const [isSaving, setIsSaving] = useState(false);
  const [editingFull, setEditingFull] = useState<Oportunidade | null>(null);
  const [isLoadingDetails, setIsLoadingDetails] = useState(false);

  const openEditFull = async (row: Oportunidade) => {
    setIsLoadingDetails(true);
    handleOpenEditForm(row);
    try {
      const fullItem = await crmService.findById(row.id);
      if (fullItem) {
        setEditingFull(fullItem);
      } else {
        toast.error('Oportunidade não encontrada.');
        handleCloseForm();
      }
    } catch (err: any) {
      toast.error(`Falha ao carregar detalhes: ${err.message}`);
      handleCloseForm();
    } finally {
      setIsLoadingDetails(false);
    }
  };

  const handleSave = async (formData: OportunidadeFormData) => {
    if (!currentEmpresa) {
      toast.error("Nenhuma empresa selecionada. Não é possível salvar.");
      return;
    }

    setIsSaving(true);
    try {
      const dataToSave = { ...formData, empresaId: currentEmpresa.id };
      
      if (editingItem?.id) {
        await updateItem(editingItem.id, dataToSave);
      } else {
        await createItem(dataToSave as Omit<Oportunidade, 'id' | 'createdAt' | 'updatedAt'>);
      }
      
      setEditingFull(null);
      handleCloseForm();
      loadItems(1); // Recarrega os dados para o Kanban
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = (id: string) => {
    useConfirmationStore.getState().show(
      'Confirmar Exclusão',
      'Tem certeza que deseja excluir esta oportunidade? A ação não pode ser desfeita.',
      () => deleteItem(id)
    );
  };

  const handleDragEnd = useCallback(async (oportunidadeId: string, novaEtapa: CrmEtapaFunil) => {
    const originalOportunidades = [...oportunidades];
    
    // Otimisticamente atualiza a UI
    const updatedOportunidades = oportunidades.map(op => 
      op.id === oportunidadeId ? { ...op, etapaFunil: novaEtapa } : op
    );
    // Para evitar que o useCrud atualize a lista e cause um "pulo"
    // setItems(updatedOportunidades); 

    try {
      await updateItem(oportunidadeId, { etapaFunil: novaEtapa });
      toast.success('Etapa atualizada!');
    } catch (error) {
      toast.error('Falha ao atualizar etapa. Revertendo.');
      // Reverte a UI em caso de erro
      // setItems(originalOportunidades);
      loadItems(1); // Força recarregamento em caso de erro
    }
  }, [oportunidades, updateItem, loadItems]);


  const oportunidadesPorEtapa = useMemo(() => {
    const grouped: { [key in CrmEtapaFunil]?: Oportunidade[] } = {};
    FUNIL_STAGES_ORDER.forEach(stage => grouped[stage] = []);
    oportunidades.forEach(op => {
      if (grouped[op.etapaFunil]) {
        grouped[op.etapaFunil]!.push(op);
      }
    });
    return grouped;
  }, [oportunidades]);

  return (
    <div>
      <Header 
        title="CRM" 
        subtitle="Gerencie suas oportunidades de negócio e funil de vendas"
      />

      <GlassCard className="mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <GlassButton icon={LayoutGrid} variant="primary">Kanban</GlassButton>
            <GlassButton icon={List} variant="secondary">Lista</GlassButton>
          </div>
          <GlassButton icon={Plus} onClick={handleOpenCreateForm}>Nova Oportunidade</GlassButton>
        </div>
      </GlassCard>

      {loading && oportunidades.length === 0 ? (
        <div className="flex justify-center items-center h-96">
          <Loader2 className="animate-spin text-blue-500" size={40} />
        </div>
      ) : error ? (
        <GlassCard className="text-center text-red-500 p-8">{error}</GlassCard>
      ) : (
        <KanbanBoard
          stages={FUNIL_STAGES_ORDER}
          oportunidadesPorEtapa={oportunidadesPorEtapa}
          onDragEnd={handleDragEnd}
          onCardClick={openEditFull}
        />
      )}

      <AnimatePresence>
        {isFormOpen && (
          <OportunidadeForm
            oportunidade={editingFull ?? editingItem}
            onSave={handleSave}
            onCancel={() => {
              setEditingFull(null);
              handleCloseForm();
            }}
            loading={isSaving || (isLoadingDetails && !!editingItem)}
          />
        )}
      </AnimatePresence>
    </div>
  );
};

export default Crm;
