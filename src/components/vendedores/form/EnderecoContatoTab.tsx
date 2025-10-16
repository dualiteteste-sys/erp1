import React from 'react';
import { Control, Controller, UseFormRegister, FieldErrors } from 'react-hook-form';
import { VendedorFormData } from '../../../schemas/vendedorSchema';
import { InputWrapper } from '../../ui/InputWrapper';
import { GlassInput } from '../../ui/GlassInput';
import { IMaskInput } from 'react-imask';

interface EnderecoContatoTabProps {
  control: Control<VendedorFormData>;
  register: UseFormRegister<VendedorFormData>;
  errors: FieldErrors<VendedorFormData>;
  onBuscaCep: (cep: string) => void;
  onEmailBlur: (email: string) => void;
}

export const EnderecoContatoTab: React.FC<EnderecoContatoTabProps> = ({ control, register, errors, onBuscaCep, onEmailBlur }) => {
  return (
    <div className="space-y-12">
      <section>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Endereço</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <Controller name="cep" control={control} render={({ field }) => (
            <InputWrapper label="CEP"><IMaskInput mask="00000-000" className="glass-input" {...field} value={field.value || ''} onBlur={(e) => onBuscaCep(e.target.value)} /></InputWrapper>
          )} />
          <InputWrapper label="Endereço" className="md:col-span-3"><GlassInput {...register('logradouro')} /></InputWrapper>
          <InputWrapper label="Número"><GlassInput {...register('numero')} /></InputWrapper>
          <InputWrapper label="Complemento"><GlassInput {...register('complemento')} /></InputWrapper>
          <InputWrapper label="Bairro" className="md:col-span-2"><GlassInput {...register('bairro')} /></InputWrapper>
          <InputWrapper label="Cidade" className="md:col-span-3"><GlassInput {...register('cidade')} /></InputWrapper>
          <InputWrapper label="UF"><GlassInput {...register('uf')} /></InputWrapper>
        </div>
      </section>

      <section>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Contato</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Controller name="telefone" control={control} render={({ field }) => (
            <InputWrapper label="Telefone"><IMaskInput mask="(00) 0000-0000" className="glass-input" {...field} value={field.value || ''} /></InputWrapper>
          )} />
          <Controller name="celular" control={control} render={({ field }) => (
            <InputWrapper label="Celular"><IMaskInput mask="(00) 00000-0000" className="glass-input" {...field} value={field.value || ''} /></InputWrapper>
          )} />
          <InputWrapper label="E-mail *" error={errors.email?.message}>
            <GlassInput {...register('email')} type="email" onBlur={(e) => onEmailBlur(e.target.value)} />
          </InputWrapper>
          <InputWrapper label="E-mail para Comunicação"><GlassInput {...register('emailComunicacao')} type="email" /></InputWrapper>
        </div>
      </section>
    </div>
  );
};
