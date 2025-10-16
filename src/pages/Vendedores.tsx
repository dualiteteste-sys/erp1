import React, { useState, useMemo } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, Edit2, Trash2, Filter, CheckCircle, XCircle, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';

import { Header } from '../components/layout/Header';
import { GlassCard } from '../components/ui/GlassCard';
import { GlassButton } from '../components/ui/GlassButton';
import { GlassInput } from '../components/ui/GlassInput';
import { Pagination } from '../components/ui/Pagination';
import { DataTable } from '../components/ui/DataTable';
import { useModalForm } from '../hooks/useModalForm';
import { Vendedor, SituacaoVendedor } from '../types';
import { useCrud } from '../hooks/useCrud';
import { VendedorForm } from '../components/vendedores/VendedorForm';
import { useEmpresa } from '../contexts/EmpresaContext';
import { VendedorFormData } from '../schemas/vendedorSchema';
import { useConfirmationStore } from '../stores/useConfirmationStore';
import { useService } from '../hooks/useService';

export const Vendedores: React.FC = () => {
  const vendedorService = useService('vendedor');
  const { 
    items: vendedores, 
    loading, 
    error, 
    createItem, 
    updateItem, 
    deleteItem,
    currentPage,
    totalPages,
    goToPage,
  } = useCrud<Vendedor>({ entityName: 'vendedor' });
  
  const { currentEmpresa } = useEmpresa();
  const { isFormOpen, editingItem, handleOpenCreateForm, handleOpenEditForm, handleCloseForm } = useModalForm<Vendedor>();
  
  const [isSaving, setIsSaving] = useState(false);
  const [filtro, setFiltro] = useState('');
  const [editingFull, setEditingFull] = useState<Vendedor | null>(null);
  const [isLoadingDetails, setIsLoadingDetails] = useState(false);

  const vendedoresFiltrados = vendedores.filter(vendedor =>
    vendedor.nome.toLowerCase().includes(filtro.toLowerCase()) ||
    (vendedor.email && vendedor.email.toLowerCase().includes(filtro.toLowerCase()))
  );

  const openEditFull = async (row: Vendedor) => {
    setIsLoadingDetails(true);
    handleOpenEditForm(row);
    try {
      const fullVendedor = await vendedorService.findById(row.id);
      if (fullVendedor) {
        setEditingFull(fullVendedor);
      } else {
        toast.error('Vendedor não encontrado.');
        handleCloseForm();
      }
    } catch (err: any) {
      toast.error(`Falha ao carregar detalhes: ${err.message}`);
      handleCloseForm();
    } finally {
      setIsLoadingDetails(false);
    }
  };

  const handleSave = async (data: VendedorFormData) => {
    if (!currentEmpresa) return;
    setIsSaving(true);
    const dataToSave = { ...data, empresaId: currentEmpresa.id };
    try {
      if (editingItem) {
        await updateItem(editingItem.id, dataToSave);
      } else {
        await createItem(dataToSave as Omit<Vendedor, 'id' | 'createdAt' | 'updatedAt'>);
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
      'Tem certeza que deseja excluir este vendedor?',
      () => deleteItem(id)
    );
  };
  
  const columns = useMemo(() => [
    { header: 'Nome', accessorKey: 'nome', cell: (item: Vendedor) => <p className="font-medium text-gray-800">{item.nome}</p> },
    { header: 'E-mail', accessorKey: 'email' },
    { header: 'CPF/CNPJ', accessorKey: 'cpfCnpj' },
    { header: 'Situação', accessorKey: 'situacao', cell: (item: Vendedor) => (
        item.situacao === SituacaoVendedor.ATIVO_COM_ACESSO || item.situacao === SituacaoVendedor.ATIVO_SEM_ACESSO ?
        <CheckCircle className="text-green-500 mx-auto" size={20} /> : 
        <XCircle className="text-red-500 mx-auto" size={20} />
    ), className: 'text-center' },
  ], []);

  return (
    <div>
      <Header title="Vendedores" subtitle="Gerencie sua equipe de vendas e comissões" />

      <GlassCard className="mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4 flex-1 min-w-[250px]">
            <GlassInput placeholder="Buscar por nome ou e-mail..." value={filtro} onChange={(e) => setFiltro(e.target.value)} className="w-full max-w-md" />
            <GlassButton icon={Filter} variant="secondary">Filtros</GlassButton>
          </div>
          <GlassButton icon={Plus} onClick={handleOpenCreateForm}>Novo Vendedor</GlassButton>
        </div>
      </GlassCard>

      <GlassCard>
        <DataTable
          data={vendedoresFiltrados}
          columns={columns}
          loading={loading && vendedores.length === 0}
          error={error}
          entityName="Vendedor"
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
          <VendedorForm
            vendedor={editingFull ?? editingItem}
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
