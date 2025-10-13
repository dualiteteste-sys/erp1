import React, { useState, useMemo, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Package, ListTree, MoreHorizontal, FileText } from 'lucide-react';
import { Produto } from '../../types';
import { ProdutoFormData, produtoSchema } from '../../schemas/produtoSchema';
import { GenericForm } from '../ui/GenericForm';
import { DadosGeraisTab } from './tabs/DadosGeraisTab';
import { DadosComplementaresTab } from './tabs/DadosComplementaresTab';
import { AtributosTab } from './tabs/AtributosTab';
import { OutrosTab } from './tabs/OutrosTab';
import { useEmpresa } from '../../contexts/EmpresaContext';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { NcmSuggestionPanel } from './NcmSuggestionPanel';

interface ProdutoFormProps {
  produto?: Partial<Produto>;
  onSave: (produto: ProdutoFormData) => void;
  onCancel: () => void;
  loading?: boolean;
}

const getInitialData = (p?: Partial<Produto>, empresaId?: string): Partial<ProdutoFormData> => ({
  id: p?.id || undefined,
  empresaId: p?.empresaId || empresaId,
  nome: p?.nome || '',
  tipo: p?.tipo,
  situacao: p?.situacao,
  codigo: p?.codigo || '',
  codigoBarras: p?.codigoBarras || '',
  unidade: p?.unidade || '',
  precoVenda: p?.precoVenda ?? 0,
  custoMedio: p?.custoMedio ?? null,
  origem: p?.origem,
  ncm: p?.ncm || '',
  cest: p?.cest || '',
  controlarEstoque: p?.controlarEstoque ?? true,
  estoqueInicial: p?.estoqueInicial ?? null,
  estoqueMinimo: p?.estoqueMinimo ?? null,
  estoqueMaximo: p?.estoqueMaximo ?? null,
  localizacao: p?.localizacao || '',
  diasPreparacao: p?.diasPreparacao ?? null,
  controlarLotes: p?.controlarLotes ?? false,
  pesoLiquido: p?.pesoLiquido ?? null,
  pesoBruto: p?.pesoBruto ?? null,
  numeroVolumes: p?.numeroVolumes ?? null,
  embalagemId: p?.embalagem?.id ?? null,
  largura: p?.largura ?? null,
  altura: p?.altura ?? null,
  comprimento: p?.comprimento ?? null,
  diametro: p?.diametro ?? null,
  marca: p?.marca || '',
  modelo: p?.modelo || '',
  disponibilidade: p?.disponibilidade || '',
  garantia: p?.garantia || '',
  videoUrl: p?.videoUrl || '',
  descricaoCurta: p?.descricaoCurta || '',
  descricaoComplementar: p?.descricaoComplementar || '',
  slug: p?.slug || '',
  tituloSeo: p?.tituloSeo || '',
  metaDescricaoSeo: p?.metaDescricaoSeo || '',
  observacoes: p?.observacoes || '',
  atributos: p?.atributos?.map(attr => ({ ...attr, id: attr.id || crypto.randomUUID() })) || [],
  fornecedores: p?.fornecedores?.map(f => ({ ...f, id: f.id || crypto.randomUUID() })) || [],
});

export const ProdutoForm: React.FC<ProdutoFormProps> = ({ produto, onSave, onCancel, loading }) => {
  const { currentEmpresa } = useEmpresa();
  const [activeTab, setActiveTab] = useState('dadosGerais');
  const [isNcmPanelOpen, setIsNcmPanelOpen] = useState(false);

  const form = useForm<ProdutoFormData>({
    resolver: zodResolver(produtoSchema),
    defaultValues: getInitialData(produto, currentEmpresa?.id),
  });

  const { control, handleSubmit, watch, setValue, reset } = form;

  useEffect(() => {
    reset(getInitialData(produto, currentEmpresa?.id));
  }, [produto, currentEmpresa, reset]);

  const handleNcmSelect = (ncm: string) => {
    setValue('ncm', ncm, { shouldValidate: true });
  };

  const tabs = useMemo(() => [
    { id: 'dadosGerais', label: 'Dados Gerais', icon: Package },
    { id: 'dadosComplementares', label: 'Dados Complementares', icon: FileText },
    { id: 'atributos', label: 'Atributos', icon: ListTree },
    { id: 'outros', label: 'Outros', icon: MoreHorizontal },
  ], []);

  const renderTabContent = () => {
    switch (activeTab) {
      case 'dadosGerais':
        return (
          <DadosGeraisTab
            control={control}
            watch={watch}
            setValue={setValue}
            onSuggestNcm={() => setIsNcmPanelOpen(true)}
            isEditing={!!produto?.id}
          />
        );
      case 'dadosComplementares':
        return <DadosComplementaresTab control={control} />;
      case 'atributos':
        return <AtributosTab control={control} />;
      case 'outros':
        return <OutrosTab control={control} />;
      default:
        return null;
    }
  };

  return (
    <>
      <GenericForm
        title={produto?.id ? 'Editar Produto' : 'Novo Produto'}
        onSave={handleSubmit(onSave)}
        onCancel={onCancel}
        loading={loading}
        size="max-w-6xl"
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

      <NcmSuggestionPanel 
        isOpen={isNcmPanelOpen}
        onClose={() => setIsNcmPanelOpen(false)}
        onSelect={handleNcmSelect}
      />
    </>
  );
};
