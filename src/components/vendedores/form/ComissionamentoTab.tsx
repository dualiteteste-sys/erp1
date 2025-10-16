import React from 'react';
import { Control, Controller, UseFormRegister, UseFormWatch } from 'react-hook-form';
import { VendedorFormData } from '../../../schemas/vendedorSchema';
import { InputWrapper } from '../../ui/InputWrapper';
import { PercentageInput } from '../../ui/PercentageInput';
import { RegraLiberacaoComissao, TipoComissao } from '../../../types';
import { motion, AnimatePresence } from 'framer-motion';

interface ComissionamentoTabProps {
  control: Control<VendedorFormData>;
  register: UseFormRegister<VendedorFormData>;
  watch: UseFormWatch<VendedorFormData>;
}

export const ComissionamentoTab: React.FC<ComissionamentoTabProps> = ({ control, register, watch }) => {
  const tipoComissao = watch('tipoComissao');

  return (
    <section className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Controller name="regraLiberacaoComissao" control={control} render={({ field }) => (
          <InputWrapper label="Regras para liberação de comissões">
            <select className="glass-input" {...field} value={field.value || ''}>
              <option value="">Selecione...</option>
              {Object.values(RegraLiberacaoComissao).map(r => <option key={r} value={r}>{r}</option>)}
            </select>
          </InputWrapper>
        )} />
        <Controller name="tipoComissao" control={control} render={({ field }) => (
          <InputWrapper label="Tipo de comissão">
            <select className="glass-input" {...field} value={field.value || ''}>
              <option value="">Selecione...</option>
              <option value={TipoComissao.FIXA}>Fixa</option>
              <option value={TipoComissao.VARIAVEL}>Variável</option>
            </select>
          </InputWrapper>
        )} />
        <AnimatePresence>
          {tipoComissao === 'fixa' && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              <Controller name="aliquotaComissao" control={control} render={({ field }) => (
                <InputWrapper label="Alíquota (%)">
                  <PercentageInput value={String(field.value || '0')} onAccept={(v) => field.onChange(v)} />
                </InputWrapper>
              )} />
            </motion.div>
          )}
        </AnimatePresence>
        <div className="md:col-span-full">
          <Controller name="desconsiderarComissionamentoLinhasProduto" control={control} render={({ field }) => (
            <label className="flex items-center gap-2 cursor-pointer"><input type="checkbox" className="form-checkbox" {...field} checked={field.value} /> Desconsiderar comissionamento das linhas de produto</label>
          )} />
        </div>
        <InputWrapper label="Observações sobre a comissão" className="md:col-span-full">
          <textarea {...register('observacoesComissao')} className="glass-input h-24 resize-y" />
        </InputWrapper>
      </div>
    </section>
  );
};
