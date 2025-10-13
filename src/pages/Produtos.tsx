import React, { useState, useMemo } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, Edit2, Trash2, Filter, CheckCircle, XCircle } from 'lucide-react';
import toast from 'react-hot-toast';

import { Header } from '../components/layout/Header';
import { GlassCard } from '../components/ui/GlassCard';
import { GlassButton } from '../components/ui/GlassButton';
import { GlassInput } from '../components/ui/GlassInput';
import { ProdutoForm } from '../components/produtos/ProdutoForm';
import { Pagination } from '../components/ui/Pagination';
import { DataTable } from '../components/ui/DataTable';

import { useModalForm } from '../hooks/useModalForm';
import { Produto, SituacaoProduto } from '../types';
import { useCrud } from '../hooks/useCrud';
import { useEmpresa } from '../contexts/EmpresaContext';
import { useConfirmationStore } from '../stores/useConfirmationStore';
import { ProdutoFormData } from '../schemas/produtoSchema';

export const Produtos: React.FC = () => {
  const {
    items: produtos,
    loading,
    error,
    createItem,
    updateItem,
    deleteItem,
    currentPage,
    totalPages,
    goToPage,
    loadItems,
  } = useCrud<Produto>({ entityName: 'produto' });

  const { currentEmpresa } = useEmpresa();

  const {
    isFormOpen,
    editingItem,
    handleOpenCreateForm,
    handleOpenEditForm,
    handleCloseForm,
  } = useModalForm<Produto>();

  const [isSaving, setIsSaving] = useState(false);
  const [filtro, setFiltro] = useState('');
  const [editingFull, setEditingFull] = useState<Produto | null>(null);

  const produtosFiltrados = produtos.filter((produto) =>
    produto.nome.toLowerCase().includes(filtro.toLowerCase()) ||
    (produto.codigo && produto.codigo.toLowerCase().includes(filtro.toLowerCase()))
  );

  // abre edição (se precisar buscar mais detalhes, pode usar seu service aqui)
  const openEditFull = async (row: Produto) => {
    setEditingFull(row);
    handleOpenEditForm(row);
  };

  /** Salvar produto — garante defaults de situacao/tipo e normaliza GTIN/NCM */
  const handleSave = async (produtoData: ProdutoFormData | any) => {
    if (!currentEmpresa) {
      toast.error('Nenhuma empresa selecionada. Não é possível salvar.');
      return;
    }

    setIsSaving(true);
    try {
      const gtinDigits =
        produtoData?.gtin
          ? String(produtoData.gtin).replace(/\D/g, '')
          : (produtoData?.codigoBarras
              ? String(produtoData.codigoBarras).replace(/\D/g, '')
              : null);

      const ncmDigits =
        produtoData?.ncm ? String(produtoData.ncm).replace(/\D/g, '') : null;

      const dataToSave = {
        ...produtoData,

        // ✅ Fallbacks garantidos
        situacao: produtoData?.situacao ?? 'Ativo',
        tipo: produtoData?.tipo ?? 'Simples',

        // normalizações
        gtin: gtinDigits,
        codigoBarras: gtinDigits,
        ncm: ncmDigits,

        empresaId: currentEmpresa.id,

        // arrays aninhados no formato esperado
        atributos: produtoData.atributos?.map(
          ({ atributo, valor }: any) => ({ atributo, valor })
        ),
        fornecedores: produtoData.fornecedores?.map(
          ({ fornecedorId, codigoNoFornecedor }: any) => ({
            fornecedorId,
            codigoNoFornecedor,
          })
        ),
      };

      // create/update
      if (editingItem?.id) {
        await updateItem(editingItem.id, dataToSave);
      } else {
        await createItem(dataToSave as Omit<Produto, 'id' | 'createdAt' | 'updatedAt'>);
      }

      setEditingFull(null);
      handleCloseForm();
      await loadItems(editingItem ? currentPage : 1);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = (id: string) => {
    useConfirmationStore.getState().show(
      'Confirmar Exclusão',
      'Tem certeza que deseja excluir este produto? A ação não pode ser desfeita.',
      () => deleteItem(id)
    );
  };

  const formatCurrency = (value: number | null | undefined) => {
    if (value === null || value === undefined) return 'N/A';
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value);
  };

  const columns = useMemo(
    () => [
      {
        header: 'Nome',
        accessorKey: 'nome',
        cell: (item: Produto) => (
          <p className="font-medium text-gray-800">{item.nome}</p>
        ),
      },
      { header: 'Código', accessorKey: 'codigo' },
      {
        header: 'Preço',
        accessorKey: 'precoVenda',
        cell: (item: Produto) => formatCurrency(item.precoVenda),
      },
      {
        header: 'Estoque',
        accessorKey: 'estoqueAtual',
        cell: (item: Produto) =>
          item.controlarEstoque &&
          item.estoqueAtual !== undefined &&
          item.estoqueAtual !== null
            ? item.estoqueAtual
            : 'N/A',
        className: 'text-center',
      },
      {
        header: 'Situação',
        accessorKey: 'situacao',
        cell: (item: Produto) =>
          item.situacao === SituacaoProduto.ATIVO ? (
            <CheckCircle className="text-green-500 mx-auto" size={20} />
          ) : (
            <XCircle className="text-red-500 mx-auto" size={20} />
          ),
        className: 'text-center',
      },
    ],
    []
  );

  return (
    <div>
      <Header title="Produtos" subtitle="Gerencie seu catálogo de produtos" />

      <GlassCard className="mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4 flex-1 min-w-[250px]">
            <GlassInput
              placeholder="Buscar por nome ou código..."
              value={filtro}
              onChange={(e) => setFiltro(e.target.value)}
              className="w-full max-w-md"
            />
            <GlassButton icon={Filter} variant="secondary">
              Filtros
            </GlassButton>
          </div>
          <GlassButton icon={Plus} onClick={handleOpenCreateForm}>
            Novo Produto
          </GlassButton>
        </div>
      </GlassCard>

      <GlassCard>
        <DataTable
          data={produtosFiltrados}
          columns={columns}
          loading={loading && produtos.length === 0}
          error={error}
          entityName="Produto"
          actions={(item) => (
            <div className="flex items-center gap-2">
              <GlassButton
                icon={Edit2}
                variant="secondary"
                size="sm"
                onClick={() => openEditFull(item)}
              />
              <GlassButton
                icon={Trash2}
                variant="danger"
                size="sm"
                onClick={() => handleDelete(item.id)}
              />
            </div>
          )}
        />
        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          onPageChange={goToPage}
        />
      </GlassCard>

      <AnimatePresence>
        {isFormOpen && (
          <ProdutoForm
            produto={editingFull ?? editingItem}
            onSave={handleSave}
            onCancel={() => {
              setEditingFull(null);
              handleCloseForm();
            }}
            loading={isSaving}
          />
        )}
      </AnimatePresence>
    </div>
  );
};
