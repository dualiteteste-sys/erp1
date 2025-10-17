import React, { useState, useMemo } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, Edit2, Trash2, Filter, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { Header } from '../components/layout/Header';
import { GlassCard } from '../components/ui/GlassCard';
import { GlassButton } from '../components/ui/GlassButton';
import { GlassInput } from '../components/ui/GlassInput';
import { Pagination } from '../components/ui/Pagination';
import { DataTable } from '../components/ui/DataTable';
import { useModalForm } from '../hooks/useModalForm';
import { PedidoVenda } from '../types';
import { useCrud } from '../hooks/useCrud';
import { useEmpresa } from '../contexts/EmpresaContext';
import { useService } from '../hooks/useService';
import { useConfirmationStore } from '../stores/useConfirmationStore';
import { PedidoVendaFormData } from '../schemas/pedidoVendaSchema';
import { PedidoVendaForm } from '../components/pedidos-venda/PedidoVendaForm';

export const PedidosVenda: React.FC = () => {
  const pedidoVendaService = useService('pedidoVenda');
  const { 
    items: pedidos, 
    loading, 
    error, 
    createItem, 
    updateItem, 
    deleteItem,
    currentPage,
    totalPages,
    goToPage,
  } = useCrud<PedidoVenda>({ entityName: 'pedidoVenda' });
  
  const { currentEmpresa } = useEmpresa();
  const { isFormOpen, editingItem, handleOpenCreateForm, handleOpenEditForm, handleCloseForm } = useModalForm<PedidoVenda>();
  
  const [isSaving, setIsSaving] = useState(false);
  const [filtro, setFiltro] = useState('');

  const [editingFull, setEditingFull] = useState<PedidoVenda | null>(null);
  const [isLoadingDetails, setIsLoadingDetails] = useState(false);

  const pedidosFiltrados = pedidos.filter(op =>
    String(op.numero).includes(filtro) ||
    (op.cliente?.nomeRazaoSocial && op.cliente.nomeRazaoSocial.toLowerCase().includes(filtro.toLowerCase()))
  );

  const openEditFull = async (row: PedidoVenda) => {
    setIsLoadingDetails(true);
    handleOpenEditForm(row);
    try {
      const fullItem = await pedidoVendaService.findById(row.id);
      if (fullItem) {
        setEditingFull(fullItem);
      } else {
        toast.error('Pedido de Venda não encontrado.');
        handleCloseForm();
      }
    } catch (err: any) {
      toast.error(`Falha ao carregar detalhes: ${err.message}`);
      handleCloseForm();
    } finally {
      setIsLoadingDetails(false);
    }
  };

  const handleSave = async (formData: PedidoVendaFormData) => {
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
        await createItem(dataToSave as Omit<PedidoVenda, 'id' | 'createdAt' | 'updatedAt'>);
      }
      
      setEditingFull(null);
      handleCloseForm();
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = (id: string) => {
    useConfirmationStore.getState().show(
      'Confirmar Exclusão',
      'Tem certeza que deseja excluir este pedido? A ação não pode ser desfeita.',
      () => deleteItem(id)
    );
  };

  const formatCurrency = (value: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
  
  const columns = useMemo(() => [
    { header: 'Nº', accessorKey: 'numero' },
    { header: 'Cliente', accessorKey: 'cliente.nomeRazaoSocial', cell: (item: PedidoVenda) => item.cliente?.nomeRazaoSocial || 'N/A' },
    { header: 'Data', accessorKey: 'dataVenda', cell: (item: PedidoVenda) => new Date(item.dataVenda).toLocaleDateString('pt-BR') },
    { header: 'Valor Total', accessorKey: 'valorTotal', cell: (item: PedidoVenda) => formatCurrency(item.valorTotal) },
    { header: 'Status', accessorKey: 'status' },
  ], []);

  return (
    <div>
      <Header 
        title="Pedidos de Venda" 
        subtitle="Crie e gerencie os pedidos dos seus clientes"
      />

      <GlassCard className="mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4 flex-1 min-w-[250px]">
            <GlassInput
              placeholder="Buscar por número ou cliente..."
              value={filtro}
              onChange={(e) => setFiltro(e.target.value)}
              className="w-full max-w-md"
            />
            <GlassButton icon={Filter} variant="secondary">Filtros</GlassButton>
          </div>
          <GlassButton icon={Plus} onClick={handleOpenCreateForm}>Novo Pedido</GlassButton>
        </div>
      </GlassCard>

      <GlassCard>
        <DataTable
          data={pedidosFiltrados}
          columns={columns}
          loading={loading && pedidos.length === 0}
          error={error}
          entityName="Pedido de Venda"
          actions={(item) => (
            <div className="flex items-center gap-2">
              <GlassButton
                icon={isLoadingDetails && editingItem?.id === item.id ? Loader2 : Edit2}
                variant="secondary"
                size="sm"
                onClick={() => openEditFull(item)}
                disabled={isLoadingDetails && editingItem?.id === item.id}
              />
              <GlassButton icon={Trash2} variant="danger" size="sm" onClick={() => handleDelete(item.id)} />
            </div>
          )}
        />
        <Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={goToPage} />
      </GlassCard>

      <AnimatePresence>
        {isFormOpen && (
          <PedidoVendaForm
            pedido={editingFull ?? editingItem}
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

export default PedidosVenda;
