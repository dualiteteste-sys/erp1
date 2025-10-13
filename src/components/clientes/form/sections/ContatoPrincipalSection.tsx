import React from 'react';
import { Control, Controller } from 'react-hook-form';
import { IMaskInput } from 'react-imask';
import { GlassInput } from '../../../ui/GlassInput';
import { InputWrapper } from '../../../ui/InputWrapper';
import { ClienteFornecedorFormData } from '../../../../schemas/clienteSchema';

interface ContatoPrincipalSectionProps {
  control: Control<ClienteFornecedorFormData>;
}

export const ContatoPrincipalSection: React.FC<ContatoPrincipalSectionProps> = ({ control }) => {
  return (
    <section>
      <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Contato Principal</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <Controller name="telefone" control={control} render={({ field }) => (
          <InputWrapper label="Telefone Fixo">
            <IMaskInput mask="(00) 0000-0000" value={field.value || ''} onAccept={field.onChange} className="glass-input" />
          </InputWrapper>
        )} />
        <Controller name="celular" control={control} render={({ field }) => (
          <InputWrapper label="Celular">
            <IMaskInput mask="(00) 00000-0000" value={field.value || ''} onAccept={field.onChange} className="glass-input" />
          </InputWrapper>
        )} />
        <Controller name="telefoneAdicional" control={control} render={({ field }) => (
          <InputWrapper label="Telefone Adicional">
            <IMaskInput mask="(00) 0000-0000" value={field.value || ''} onAccept={field.onChange} className="glass-input" />
          </InputWrapper>
        )} />
        <Controller name="email" control={control} render={({ field, fieldState }) => (
          <InputWrapper label="E-mail Principal" error={fieldState.error?.message}>
            <GlassInput type="email" {...field} />
          </InputWrapper>
        )} />
        <Controller name="emailNfe" control={control} render={({ field, fieldState }) => (
          <InputWrapper label="E-mail para NF-e" error={fieldState.error?.message}>
            <GlassInput type="email" {...field} />
          </InputWrapper>
        )} />
        <Controller name="website" control={control} render={({ field, fieldState }) => (
          <InputWrapper label="Site" error={fieldState.error?.message}>
            <GlassInput {...field} />
          </InputWrapper>
        )} />
      </div>
    </section>
  );
};
