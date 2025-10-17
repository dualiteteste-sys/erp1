import React from 'react';
import { Control, Controller, FieldErrors } from 'react-hook-form';
import { PedidoVendaFormData } from '../../../schemas/pedidoVendaSchema';
import { InputWrapper } from '../../ui/InputWrapper';
import { GlassInput } from '../../ui/GlassInput';
import { AutocompleteInput } from '../../ui/AutocompleteInput';
import { useService } from '../../../hooks/useService';
import { useEmpresa } from '../../../contexts/EmpresaContext';
import { PedidoVenda, StatusPedidoVenda } from '../../../types';

interface DadosGeraisTabProps {
  control: Control<PedidoVendaFormData>;
  errors: FieldErrors<PedidoVendaFormData>;
  pedido?: Partial<PedidoVenda>;
}

export const DadosGeraisTab: React.FC<DadosGeraisTabProps> = ({ control, errors, pedido }) => {
  const { currentEmpresa } = useEmpresa();
  const clienteService = useService('cliente');
  const vendedorService = useService('vendedor');

  const fetchClientes = React.useCallback(async (query: string) => {
    if (!currentEmpresa?.id) return [];
    const results = await clienteService.search(currentEmpresa.id, query, 'cliente');
    return results.map(c => ({ value: c.id, label: c.nomeRazaoSocial }));
  }, [clienteService, currentEmpresa]);

  const fetchVendedores = React.useCallback(async (query: string) => {
    if (!currentEmpresa?.id) return [];
    const { data } = await vendedorService.getAll(currentEmpresa.id, { page: 1, pageSize: 100 });
    return data
      .filter(v => v.nome.toLowerCase().includes(query.toLowerCase()))
      .map(v => ({ value: v.id, label: v.nome }));
  }, [vendedorService, currentEmpresa]);

  return (
    <div className="space-y-6">
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
                initialLabel={pedido?.cliente?.nomeRazaoSocial}
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
                initialLabel={pedido?.vendedor?.nome}
                placeholder="Buscar vendedor..."
              />
            </InputWrapper>
          )}
        />
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Controller
          name="naturezaOperacao"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Natureza da Operação *" error={errors.naturezaOperacao?.message}>
              <GlassInput {...field} />
            </InputWrapper>
          )}
        />
        <Controller
          name="dataVenda"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Data da Venda *" error={errors.dataVenda?.message}>
              <GlassInput
                type="date"
                value={field.value ? new Date(field.value).toISOString().split('T')[0] : ''}
                onChange={e => field.onChange(e.target.valueAsDate)}
              />
            </InputWrapper>
          )}
        />
         <Controller
          name="status"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Status *" error={errors.status?.message}>
              <select className="glass-input" {...field}>
                {Object.values(StatusPedidoVenda).map(s => <option key={s} value={s}>{s}</option>)}
              </select>
            </InputWrapper>
          )}
        />
      </div>
    </div>
  );
};
