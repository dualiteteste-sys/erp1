import React from 'react';
import { Control, Controller, FieldErrors } from 'react-hook-form';
import { OportunidadeFormData } from '../../../schemas/crmSchema';
import { InputWrapper } from '../../ui/InputWrapper';
import { GlassInput } from '../../ui/GlassInput';
import { AutocompleteInput } from '../../ui/AutocompleteInput';
import { useService } from '../../../hooks/useService';
import { useEmpresa } from '../../../contexts/EmpresaContext';
import { CrmEtapaFunil, CrmStatusOportunidade, Oportunidade } from '../../../types';
import { CurrencyInput } from '../../ui/CurrencyInput';

interface DadosGeraisTabProps {
  control: Control<OportunidadeFormData>;
  errors: FieldErrors<OportunidadeFormData>;
  oportunidade?: Partial<Oportunidade>;
}

export const DadosGeraisTab: React.FC<DadosGeraisTabProps> = ({ control, errors, oportunidade }) => {
  const { currentEmpresa } = useEmpresa();
  const clienteService = useService('cliente');
  const vendedorService = useService('vendedor');

  const fetchClientes = React.useCallback(async (query: string) => {
    if (!currentEmpresa?.id) return [];
    // Utiliza o método de busca otimizado que já filtra no backend
    const results = await clienteService.search(currentEmpresa.id, query, 'cliente');
    return results.map(c => ({ value: c.id, label: c.nomeRazaoSocial }));
  }, [clienteService, currentEmpresa]);

  const fetchVendedores = React.useCallback(async (query: string) => {
    if (!currentEmpresa?.id) return [];
    const { data } = await vendedorService.getAll(currentEmpresa.id, { page: 1, pageSize: 100 });
    return data.filter(v => v.nome.toLowerCase().includes(query.toLowerCase())).map(v => ({ value: v.id, label: v.nome }));
  }, [vendedorService, currentEmpresa]);

  return (
    <div className="space-y-6">
      <Controller
        name="titulo"
        control={control}
        render={({ field }) => (
          <InputWrapper label="Título da Oportunidade *" error={errors.titulo?.message}>
            <GlassInput {...field} placeholder="Ex: Projeto de novo site para Empresa X" />
          </InputWrapper>
        )}
      />
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Controller
          name="clienteId"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Cliente *" error={errors.clienteId?.message}>
              <AutocompleteInput
                value={field.value}
                onValueChange={(val) => field.onChange(val)}
                fetchSuggestions={fetchClientes}
                initialLabel={oportunidade?.cliente?.nomeRazaoSocial}
                placeholder="Buscar cliente..."
              />
            </InputWrapper>
          )}
        />
        <Controller
          name="vendedorId"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Vendedor Responsável" error={errors.vendedorId?.message}>
              <AutocompleteInput
                value={field.value || ''}
                onValueChange={(val) => field.onChange(val)}
                fetchSuggestions={fetchVendedores}
                initialLabel={oportunidade?.vendedor?.nome}
                placeholder="Buscar vendedor..."
              />
            </InputWrapper>
          )}
        />
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Controller
          name="valor"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Valor Estimado *" error={errors.valor?.message}>
              <CurrencyInput value={field.value} onAccept={(value) => field.onChange(value)} />
            </InputWrapper>
          )}
        />
        <Controller
          name="dataFechamentoPrevista"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Data de Fechamento Prevista *" error={errors.dataFechamentoPrevista?.message}>
              <GlassInput
                type="date"
                value={field.value ? new Date(field.value).toISOString().split('T')[0] : ''}
                onChange={e => field.onChange(e.target.valueAsDate)}
              />
            </InputWrapper>
          )}
        />
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Controller
          name="etapaFunil"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Etapa do Funil *" error={errors.etapaFunil?.message}>
              <select className="glass-input" {...field}>
                {Object.values(CrmEtapaFunil).map(etapa => <option key={etapa} value={etapa}>{etapa}</option>)}
              </select>
            </InputWrapper>
          )}
        />
        <Controller
          name="status"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Status *" error={errors.status?.message}>
              <select className="glass-input" {...field}>
                {Object.values(CrmStatusOportunidade).map(status => <option key={status} value={status}>{status}</option>)}
              </select>
            </InputWrapper>
          )}
        />
      </div>
    </div>
  );
};
