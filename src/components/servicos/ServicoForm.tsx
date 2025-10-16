import React from 'react';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { GenericForm } from '../ui/GenericForm';
import { GlassInput } from '../ui/GlassInput';
import { InputWrapper } from '../ui/InputWrapper';
import { CurrencyInput } from '../ui/CurrencyInput';
import { Servico, SituacaoServico } from '../../types';
import { ServicoFormData, servicoSchema } from '../../schemas/servicoSchema';
import { Search } from 'lucide-react';

interface ServicoFormProps {
  servico?: Partial<Servico>;
  onSave: (data: ServicoFormData) => void;
  onCancel: () => void;
  loading: boolean;
}

const SearchInput: React.FC<{ children: React.ReactNode }> = ({ children }) => (
    <div className="relative">
        {children}
        <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
            <Search className="text-gray-400" size={18} />
        </div>
    </div>
);

export const ServicoForm: React.FC<ServicoFormProps> = ({ servico, onSave, onCancel, loading }) => {
  const { control, handleSubmit, register, formState: { errors } } = useForm<ServicoFormData>({
    resolver: zodResolver(servicoSchema),
    defaultValues: {
      descricao: servico?.descricao || '',
      codigo: servico?.codigo || '',
      preco: servico?.preco || 0,
      unidade: servico?.unidade || '',
      situacao: servico?.situacao || SituacaoServico.ATIVO,
      codigoServico: servico?.codigoServico || '',
      nbs: servico?.nbs || '',
      descricaoComplementar: servico?.descricaoComplementar || '',
      observacoes: servico?.observacoes || '',
    },
  });

  return (
    <GenericForm
      title={servico?.id ? 'Editar Serviço' : 'Novo Serviço'}
      onSave={handleSubmit(onSave)}
      onCancel={onCancel}
      loading={loading}
      size="max-w-4xl"
    >
      <div className="space-y-8">
        {/* Top section */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <InputWrapper label="Descrição *" error={errors.descricao?.message} className="md:col-span-2">
            <GlassInput {...register('descricao')} placeholder="Descrição completa do serviço" />
          </InputWrapper>
          <InputWrapper label="Código" error={errors.codigo?.message}>
            <GlassInput {...register('codigo')} placeholder="Código ou referência (opcional)" />
          </InputWrapper>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Controller
              name="preco"
              control={control}
              render={({ field, fieldState }) => (
                <InputWrapper label="Preço *" error={fieldState.error?.message}>
                  <CurrencyInput 
                    value={field.value ?? 0} 
                    onAccept={(value) => field.onChange(value)}
                  />
                </InputWrapper>
              )}
            />
            <InputWrapper label="Unidade" error={errors.unidade?.message}>
                <GlassInput {...register('unidade')} placeholder="Ex: Pç, Kg,..." />
            </InputWrapper>
            <Controller
              name="situacao"
              control={control}
              render={({ field }) => (
                <InputWrapper label="Situação" helpText="Estado atual">
                  <select className="glass-input" {...field} value={field.value || ''}>
                    {Object.values(SituacaoServico).map(s => <option key={s} value={s}>{s}</option>)}
                  </select>
                </InputWrapper>
              )}
            />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <InputWrapper label="Código do serviço conforme tabela de serviços" error={errors.codigoServico?.message}>
                <SearchInput>
                    <GlassInput {...register('codigoServico')} />
                </SearchInput>
            </InputWrapper>
            <InputWrapper label="Nomenclatura brasileira de serviço (NBS)" error={errors.nbs?.message} helpText="Necessária para o IBPT">
                <SearchInput>
                    <GlassInput {...register('nbs')} />
                </SearchInput>
            </InputWrapper>
        </div>
        
        <hr className="border-white/20" />

        {/* Bottom section */}
        <InputWrapper label="Descrição Complementar" error={errors.descricaoComplementar?.message} helpText="Campo exibido em propostas comerciais e pedidos de venda.">
            <textarea
                {...register('descricaoComplementar')}
                className="glass-input w-full h-48 resize-y"
                placeholder="Detalhes adicionais sobre o serviço..."
            />
        </InputWrapper>

        <InputWrapper label="Observações" error={errors.observacoes?.message} helpText="Observações gerais sobre o serviço.">
            <textarea
                {...register('observacoes')}
                className="glass-input w-full h-32 resize-y"
                placeholder="Informações internas ou lembretes..."
            />
        </InputWrapper>

      </div>
    </GenericForm>
  );
};
