import React from 'react';
import { Control, Controller, UseFormRegister, UseFormWatch, FieldErrors } from 'react-hook-form';
import { VendedorFormData } from '../../../schemas/vendedorSchema';
import { InputWrapper } from '../../ui/InputWrapper';
import { GlassInput } from '../../ui/GlassInput';
import { IMaskInput } from 'react-imask';
import { motion, AnimatePresence } from 'framer-motion';
import { TipoPessoaVendedor, TipoContribuinteIcms, SituacaoVendedor } from '../../../types';

interface DadosGeraisTabProps {
  control: Control<VendedorFormData>;
  register: UseFormRegister<VendedorFormData>;
  watch: UseFormWatch<VendedorFormData>;
  errors: FieldErrors<VendedorFormData>;
  onBuscaCnpj: (cnpj: string) => void;
  onEmailBlur: (email: string) => void;
  onBuscaCep: (cep: string) => void;
}

export const DadosGeraisTab: React.FC<DadosGeraisTabProps> = ({ control, register, watch, errors, onBuscaCnpj, onEmailBlur, onBuscaCep }) => {
  const tipoPessoa = watch('tipoPessoa');

  return (
    <div className="space-y-12">
      <section>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Informações Principais</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          
          <Controller name="tipoPessoa" control={control} render={({ field }) => (
            <InputWrapper label="Tipo de Pessoa">
              <select className="glass-input" {...field}>
                {Object.values(TipoPessoaVendedor).map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </InputWrapper>
          )} />

          <AnimatePresence mode="wait">
            {tipoPessoa === TipoPessoaVendedor.PESSOA_FISICA && (
              <motion.div key="pf" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="contents">
                <Controller name="cpfCnpj" control={control} render={({ field }) => (
                  <InputWrapper label="CPF"><IMaskInput mask="000.000.000-00" className="glass-input" {...field} value={field.value || ''} /></InputWrapper>
                )} />
              </motion.div>
            )}
            {tipoPessoa === TipoPessoaVendedor.PESSOA_JURIDICA && (
              <motion.div key="pj" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="contents">
                <Controller name="cpfCnpj" control={control} render={({ field }) => (
                  <InputWrapper label="CNPJ"><IMaskInput mask="00.000.000/0000-00" className="glass-input" {...field} value={field.value || ''} onBlur={(e) => onBuscaCnpj(e.target.value)} /></InputWrapper>
                )} />
              </motion.div>
            )}
            {(tipoPessoa === TipoPessoaVendedor.ESTRANGEIRO || tipoPessoa === TipoPessoaVendedor.ESTRANGEIRO_NO_BRASIL) && (
              <motion.div key="estrangeiro" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="contents">
                <InputWrapper label="Documento de Identificação"><GlassInput {...register('documentoIdentificacao')} /></InputWrapper>
                <InputWrapper label="País"><GlassInput {...register('pais')} /></InputWrapper>
              </motion.div>
            )}
          </AnimatePresence>

          <InputWrapper label="Nome / Razão Social *" error={errors.nome?.message} className="lg:col-span-2">
            <GlassInput {...register('nome')} />
          </InputWrapper>
          
          <InputWrapper label="Nome Fantasia / Apelido">
            <GlassInput {...register('fantasia')} />
          </InputWrapper>

          <InputWrapper label="Código">
            <GlassInput {...register('codigo')} />
          </InputWrapper>
          
          <Controller name="contribuinteIcms" control={control} render={({ field }) => (
            <InputWrapper label="Contribuinte ICMS">
              <select className="glass-input" {...field} value={field.value || ''}>
                <option value="">Selecione...</option>
                {Object.values(TipoContribuinteIcms).map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </InputWrapper>
          )} />
          <InputWrapper label="Inscrição Estadual"><GlassInput {...register('inscricaoEstadual')} /></InputWrapper>
          <Controller name="situacao" control={control} render={({ field }) => (
            <InputWrapper label="Situação">
              <select className="glass-input" {...field}>
                {Object.values(SituacaoVendedor).map(s => <option key={s} value={s}>{s}</option>)}
              </select>
            </InputWrapper>
          )} />
        </div>
      </section>

      <section>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Endereço e Contato</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <Controller name="cep" control={control} render={({ field }) => (
            <InputWrapper label="CEP"><IMaskInput mask="00000-000" className="glass-input" {...field} value={field.value || ''} onBlur={(e) => onBuscaCep(e.target.value)} /></InputWrapper>
          )} />
          <InputWrapper label="Endereço" className="md:col-span-3"><GlassInput {...register('logradouro')} /></InputWrapper>
          <InputWrapper label="Número"><GlassInput {...register('numero')} /></InputWrapper>
          <InputWrapper label="Complemento"><GlassInput {...register('complemento')} /></InputWrapper>
          <InputWrapper label="Bairro" className="md:col-span-2"><GlassInput {...register('bairro')} /></InputWrapper>
          <InputWrapper label="Cidade" className="md:col-span-2"><GlassInput {...register('cidade')} /></InputWrapper>
          <InputWrapper label="UF" className="md:col-span-2"><GlassInput {...register('uf')} /></InputWrapper>
        </div>
         <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mt-6">
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
