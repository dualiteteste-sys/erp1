import React, { useState, useMemo, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Info, FileText, Paperclip, Contact2 } from 'lucide-react';
import { ClienteFornecedor, TipoPessoa, TipoContato } from '../../types';
import { clienteFornecedorSchema, ClienteFornecedorFormData } from '../../schemas/clienteSchema';
import { GenericForm } from '../ui/GenericForm';
import { DadosGeraisTab } from './form/DadosGeraisTab';
import { AnexosTab } from './form/AnexosTab';
import { ObservacoesTab } from './form/ObservacoesTab';
import { ContatosTab } from './form/ContatosTab';
import { useProfile } from '../../contexts/ProfileContext';
import { useEmpresa } from '../../contexts/EmpresaContext';

interface ClienteFormProps {
  cliente?: Partial<ClienteFornecedor>;
  onSave: (cliente: ClienteFornecedorFormData) => void;
  onCancel: () => void;
  loading?: boolean;
}

const getInitialData = (c?: Partial<ClienteFornecedor>, empresaId?: string): Partial<ClienteFornecedorFormData> => ({
  id: c?.id,
  empresaId: c?.empresaId || empresaId,
  nomeRazaoSocial: c?.nomeRazaoSocial || '',
  fantasia: c?.fantasia || '',
  tipoPessoa: c?.tipoPessoa || TipoPessoa.PJ,
  tipoContato: c?.tipoContato || TipoContato.CLIENTE,
  cnpjCpf: c?.cnpjCpf || '',
  inscricaoEstadual: c?.inscricaoEstadual || '',
  inscricaoMunicipal: c?.inscricaoMunicipal || '',
  rg: c?.rg || '',
  rnm: c?.rnm || '',
  
  cep: c?.cep || '',
  endereco: c?.endereco || '',
  numero: c?.numero || '',
  complemento: c?.complemento || '',
  bairro: c?.bairro || '',
  municipio: c?.municipio || '',
  uf: c?.uf || '',
  
  cobrancaDiferente: c?.cobrancaDiferente || false,
  cobrCep: c?.cobrCep || '',
  cobrEndereco: c?.cobrEndereco || '',
  cobrNumero: c?.cobrNumero || '',
  cobrComplemento: c?.cobrComplemento || '',
  cobrBairro: c?.cobrBairro || '',
  cobrMunicipio: c?.cobrMunicipio || '',
  cobrUf: c?.cobrUf || '',

  telefone: c?.telefone || '',
  telefoneAdicional: c?.telefoneAdicional || '',
  celular: c?.celular || '',
  email: c?.email || '',
  emailNfe: c?.emailNfe || '',
  website: c?.website || '',
  
  observacoes: c?.observacoes || '',
  contatos: c?.contatos || [],
  anexos: c?.anexos || [],
});

export const ClienteForm: React.FC<ClienteFormProps> = ({ cliente, onSave, onCancel, loading }) => {
  const [activeTab, setActiveTab] = useState('dadosGerais');
  const { hasPermission } = useProfile();
  const { currentEmpresa } = useEmpresa();

  const form = useForm<ClienteFornecedorFormData>({
    resolver: zodResolver(clienteFornecedorSchema),
    defaultValues: getInitialData(cliente, currentEmpresa?.id),
  });

  const { control, handleSubmit, register, watch, setValue } = form;

  useEffect(() => {
    form.reset(getInitialData(cliente, currentEmpresa?.id));
  }, [cliente, currentEmpresa, form]);

  const tabs = useMemo(() => [
    { id: 'dadosGerais', label: 'Dados Gerais', icon: Info },
    { id: 'contatos', label: 'Contatos Adicionais', icon: Contact2 },
    { id: 'anexos', label: 'Anexos', icon: Paperclip },
    { id: 'observacoes', label: 'Observações', icon: FileText },
  ], []);

  const renderTabContent = () => {
    switch (activeTab) {
      case 'dadosGerais':
        return <DadosGeraisTab control={control} watch={watch} setValue={setValue} />;
      case 'contatos':
        return <ContatosTab control={control} />;
      case 'anexos':
        return <AnexosTab attachments={watch('anexos') || []} setValue={setValue} />;
      case 'observacoes':
        return <ObservacoesTab register={register} />;
      default:
        return null;
    }
  };

  return (
    <GenericForm
      title={cliente?.id ? 'Editar Cadastro' : 'Novo Cadastro'}
      onSave={handleSubmit(onSave)}
      onCancel={onCancel}
      loading={loading}
      canSave={hasPermission('clientes.escrever')}
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
