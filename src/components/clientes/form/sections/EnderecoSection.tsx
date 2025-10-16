import React from 'react';
import { Control, Controller, UseFormWatch } from 'react-hook-form';
import { IMaskInput } from 'react-imask';
import { motion, AnimatePresence } from 'framer-motion';
import { GlassInput } from '../../../ui/GlassInput';
import { InputWrapper } from '../../../ui/InputWrapper';
import { ClienteFornecedorFormData } from '../../../../schemas/clienteSchema';

interface EnderecoSectionProps {
  control: Control<ClienteFornecedorFormData>;
  watch: UseFormWatch<ClienteFornecedorFormData>;
  onBuscaCep: (cep: string, isCobranca?: boolean) => void;
}

const ufs = ["AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"];

export const EnderecoSection: React.FC<EnderecoSectionProps> = ({ control, watch, onBuscaCep }) => {
  const cobrancaDiferente = watch('cobrancaDiferente');

  return (
    <section>
      <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Endereço Principal</h3>
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Controller name="cep" control={control} render={({ field }) => (
          <InputWrapper label="CEP">
            <IMaskInput mask="00000-000" value={field.value || ''} onAccept={(v) => { field.onChange(v); if ((v as string).replace(/\D/g, '').length === 8) onBuscaCep(v as string); }} className="glass-input" />
          </InputWrapper>
        )} />
        <Controller name="municipio" control={control} render={({ field }) => (
          <InputWrapper label="Município" className="md:col-span-2">
            <GlassInput {...field} />
          </InputWrapper>
        )} />
        <Controller name="uf" control={control} render={({ field }) => (
          <InputWrapper label="UF">
            <select className="glass-input" {...field} value={field.value || ''}><option value="">Selecione...</option>{ufs.map(uf => <option key={uf} value={uf}>{uf}</option>)}</select>
          </InputWrapper>
        )} />
        <Controller name="endereco" control={control} render={({ field }) => (
          <InputWrapper label="Endereço" className="md:col-span-3">
            <GlassInput {...field} />
          </InputWrapper>
        )} />
        <Controller name="numero" control={control} render={({ field }) => (
          <InputWrapper label="Número"><GlassInput {...field} /></InputWrapper>
        )} />
        <Controller name="bairro" control={control} render={({ field }) => (
          <InputWrapper label="Bairro" className="md:col-span-2"><GlassInput {...field} /></InputWrapper>
        )} />
        <Controller name="complemento" control={control} render={({ field }) => (
          <InputWrapper label="Complemento"><GlassInput {...field} /></InputWrapper>
        )} />
      </div>
      
      <div className="mt-6">
        <Controller name="cobrancaDiferente" control={control} render={({ field }) => (
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" {...field} checked={field.value} className="form-checkbox" />
            Endereço de cobrança é diferente do principal
          </label>
        )} />
      </div>

      <AnimatePresence>
        {cobrancaDiferente && (
          <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="overflow-hidden">
            <div className="mt-6 pt-6 border-t border-white/20">
                <h3 className="text-lg font-semibold text-gray-800 mb-4">Endereço de Cobrança</h3>
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  <Controller name="cobrCep" control={control} render={({ field }) => (
                    <InputWrapper label="CEP Cobrança"><IMaskInput mask="00000-000" value={field.value || ''} onAccept={(v) => { field.onChange(v); if ((v as string).replace(/\D/g, '').length === 8) onBuscaCep(v as string, true); }} className="glass-input" /></InputWrapper>
                  )} />
                  <Controller name="cobrMunicipio" control={control} render={({ field }) => (
                    <InputWrapper label="Município Cobrança" className="md:col-span-2"><GlassInput {...field} /></InputWrapper>
                  )} />
                  <Controller name="cobrUf" control={control} render={({ field }) => (
                    <InputWrapper label="UF Cobrança"><select className="glass-input" {...field} value={field.value || ''}><option value="">Selecione...</option>{ufs.map(uf => <option key={uf} value={uf}>{uf}</option>)}</select></InputWrapper>
                  )} />
                  <Controller name="cobrEndereco" control={control} render={({ field }) => (
                    <InputWrapper label="Endereço Cobrança" className="md:col-span-3"><GlassInput {...field} /></InputWrapper>
                  )} />
                  <Controller name="cobrNumero" control={control} render={({ field }) => (
                    <InputWrapper label="Número Cobrança"><GlassInput {...field} /></InputWrapper>
                  )} />
                  <Controller name="cobrBairro" control={control} render={({ field }) => (
                    <InputWrapper label="Bairro Cobrança" className="md:col-span-2"><GlassInput {...field} /></InputWrapper>
                  )} />
                  <Controller name="cobrComplemento" control={control} render={({ field }) => (
                    <InputWrapper label="Complemento Cobrança"><GlassInput {...field} /></InputWrapper>
                  )} />
                </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  );
};
