import React from 'react';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { GenericForm } from '../ui/GenericForm';
import { GlassInput } from '../ui/GlassInput';
import { InputWrapper } from '../ui/InputWrapper';
import { CurrencyInput } from '../ui/CurrencyInput';
import { Servico, SituacaoServico } from '../../types';
import { ServicoFormData, servicoSchema } from '../../schemas/servicoSchema';

interface ServicoFormProps {
  servico?: Partial<Servico>;
  onSave: (data: ServicoFormData) => void;
  onCancel: () => void;
  loading: boolean;
}

export const ServicoForm: React.FC<ServicoFormProps> = ({ servico, onSave, onCancel, loading }) => {
  const { control, handleSubmit, register, formState: { errors } } = useForm<ServicoFormData>({
    resolver: zodResolver(servicoSchema),
    defaultValues: {
      descricao: servico?.descricao || '',
      preco: servico?.preco || 0,
      situacao: servico?.situacao || SituacaoServico.ATIVO,
    },
  });

  return (
    <GenericForm
      title={servico?.id ? 'Editar Serviço' : 'Novo Serviço'}
      onSave={handleSubmit(onSave)}
      onCancel={onCancel}
      loading={loading}
      size="max-w-2xl"
    >
      <div className="space-y-6">
        <InputWrapper label="Descrição *" error={errors.descricao?.message}>
          <GlassInput {...register('descricao')} />
        </InputWrapper>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
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
            <Controller
              name="situacao"
              control={control}
              render={({ field }) => (
                <InputWrapper label="Situação">
                  <select className="glass-input" {...field}>
                    {Object.values(SituacaoServico).map(s => <option key={s} value={s}>{s}</option>)}
                  </select>
                </InputWrapper>
              )}
            />
        </div>
      </div>
    </GenericForm>
  );
};
