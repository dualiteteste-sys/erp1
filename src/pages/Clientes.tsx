import React, { useState, useMemo } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, Edit2, Trash2, Filter } from 'lucide-react';
import toast from 'react-hot-toast';
import { Header } from '../components/layout/Header';
import { GlassCard } from '../components/ui/GlassCard';
import { GlassButton } from '../components/ui/GlassButton';
import { GlassInput } from '../components/ui/GlassInput';
import { ClienteForm } from '../components/clientes/ClienteForm';
import { Pagination } from '../components/ui/Pagination';
import { DataTable } from '../components/ui/DataTable';
import { useModalForm } from '../hooks/useModalForm';
import { ClienteFornecedor, ClienteAnexo } from '../types';
import { useCrud } from '../hooks/useCrud';
import { useEmpresa } from '../contexts/EmpresaContext';
import { useProfile } from '../contexts/ProfileContext';
import { ClienteFornecedorFormData } from '../schemas/clienteSchema';
import { useService } from '../hooks/useService';
import { useConfirmationStore } from '../stores/useConfirmationStore';

const isFile = (item: any): item is File => item instanceof File;

export const Clientes: React.FC = () => {
  const clienteService = useService('cliente');
  const { 
    items: clientes, 
    loading, 
    error, 
    createItem, 
    updateItem, 
    deleteItem,
    currentPage,
    totalPages,
    goToPage,
    loadItems,
  } = useCrud<ClienteFornecedor>({ entityName: 'cliente' });
  
  const { currentEmpresa } = useEmpresa();
  const { hasPermission } = useProfile();
  const { isFormOpen, editingItem, handleOpenCreateForm, handleOpenEditForm, handleCloseForm } = useModalForm<ClienteFornecedor>();
  
  const [isSaving, setIsSaving] = useState(false);
  const [filtro, setFiltro] = useState('');

  const clientesFiltrados = clientes.filter(cliente =>
    cliente.nomeRazaoSocial.toLowerCase().includes(filtro.toLowerCase()) ||
    (cliente.email && cliente.email.toLowerCase().includes(filtro.toLowerCase())) ||
    (cliente.cnpjCpf && cliente.cnpjCpf.includes(filtro))
  );

  const handleSave = async (formData: ClienteFornecedorFormData) => {
    if (!currentEmpresa) {
      toast.error("Nenhuma empresa selecionada. Não é possível salvar.");
      return;
    }

    setIsSaving(true);
    try {
      const filesToUpload = (formData.anexos || []).filter(isFile);
      const existingAnexos = (formData.anexos || []).filter((a): a is ClienteAnexo => !isFile(a));
      
      const dataToSave = { ...formData, empresaId: currentEmpresa.id, anexos: existingAnexos };
      
      let savedClient: ClienteFornecedor;

      if (editingItem?.id) {
        savedClient = await updateItem(editingItem.id, dataToSave);
        
        const originalAnexos = editingItem.anexos || [];
        const anexosToDelete = originalAnexos.filter(
          (orig): orig is ClienteAnexo => !isFile(orig) && !existingAnexos.some(ex => ex.id === orig.id)
        );
        for (const anexo of anexosToDelete) {
          await clienteService.deleteAnexo(anexo.id, anexo.storagePath);
        }

      } else {
        savedClient = await createItem(dataToSave as Omit<ClienteFornecedor, 'id' | 'createdAt' | 'updatedAt'>);
      }

      if (savedClient?.id) {
        for (const file of filesToUpload) {
          await clienteService.uploadAnexo(currentEmpresa.id, savedClient.id, file);
        }
      }
      
      handleCloseForm();
      await loadItems(editingItem ? currentPage : 1);

    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = (id: string) => {
    useConfirmationStore.getState().show(
      'Confirmar Exclusão',
      'Tem certeza que deseja excluir este registro? A ação não pode ser desfeita.',
      () => deleteItem(id)
    );
  };
  
  const columns = useMemo(() => [
    { header: 'Nome / Razão Social', accessorKey: 'nomeRazaoSocial', cell: (item: ClienteFornecedor) => (
      <>
        <p className="font-medium text-gray-800">{item.nomeRazaoSocial}</p>
        {item.fantasia && <p className="text-sm text-gray-600">{item.fantasia}</p>}
      </>
    )},
    { header: 'CPF / CNPJ', accessorKey: 'cnpjCpf' },
    { header: 'Email', accessorKey: 'email' },
    { header: 'Telefone', accessorKey: 'celular', cell: (item: ClienteFornecedor) => item.celular || item.telefone },
  ], []);

  return (
    <div>
      <Header 
        title="Clientes e Fornecedores" 
        subtitle="Gerencie seus contatos, clientes, fornecedores e transportadoras"
      />

      <GlassCard className="mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4 flex-1 min-w-[250px]">
            <GlassInput
              placeholder="Buscar por nome, email ou documento..."
              value={filtro}
              onChange={(e) => setFiltro(e.target.value)}
              className="w-full max-w-md"
            />
            <GlassButton icon={Filter} variant="secondary">Filtros</GlassButton>
          </div>
          {hasPermission('clientes.escrever') && (
            <GlassButton icon={Plus} onClick={handleOpenCreateForm}>Novo Cadastro</GlassButton>
          )}
        </div>
      </GlassCard>

      <GlassCard>
        <DataTable
          data={clientesFiltrados}
          columns={columns}
          loading={loading && clientes.length === 0}
          error={error}
          entityName="Cliente/Fornecedor"
          actions={(item) => (
            <div className="flex items-center gap-2">
              {hasPermission('clientes.escrever') && (
                <GlassButton icon={Edit2} variant="secondary" size="sm" onClick={() => handleOpenEditForm(item)} />
              )}
              {hasPermission('clientes.excluir') && (
                <GlassButton icon={Trash2} variant="danger" size="sm" onClick={() => handleDelete(item.id)} />
              )}
            </div>
          )}
        />
        <Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={goToPage} />
      </GlassCard>

      <AnimatePresence>
        {isFormOpen && (
          <ClienteForm
            cliente={editingItem}
            onSave={handleSave}
            onCancel={handleCloseForm}
            loading={isSaving}
          />
        )}
      </AnimatePresence>
    </div>
  );
};
