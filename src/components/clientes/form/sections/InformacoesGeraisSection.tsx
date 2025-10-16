import React, { useCallback } from 'react';
import { Control, Controller, UseFormWatch } from 'react-hook-form';
import { IMaskInput } from 'react-imask';
import { motion, AnimatePresence } from 'framer-motion';
import toast from 'react-hot-toast';
import { TipoPessoa, TipoContato } from '../../../../types';
import { GlassInput } from '../../../ui/GlassInput';
import { InputWrapper } from '../../../ui/InputWrapper';
import { ClienteFornecedorFormData } from '../../../../schemas/clienteSchema';
import { isValidCPF, isValidCNPJ } from '../../../../lib/utils';
import { supabase } from '../../../../lib/supabaseClient';
import { useEmpresa } from '../../../../contexts/EmpresaContext';

interface InformacoesGeraisSectionProps {
  control: Control<ClienteFornecedorFormData>;
  watch: UseFormWatch<ClienteFornecedorFormData>;
  onBuscaCnpj: (cnpj: string) => void;
}

const motionProps = {
  initial: { opacity: 0, y: -10 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: 10 },
  transition: { duration: 0.2 },
};

export const InformacoesGeraisSection: React.FC<InformacoesGeraisSectionProps> = ({ control, watch, onBuscaCnpj }) => {
  const tipoPessoa = watch('tipoPessoa');
  const { currentEmpresa } = useEmpresa();

  const handleCpfBlur = useCallback(async (cpf: string) => {
    if (!cpf) return;
    
    if (!isValidCPF(cpf)) {
      toast.error('O CPF informado é inválido.');
      return;
    }

    if (!currentEmpresa?.id) {
      toast.error('Nenhuma empresa selecionada para verificar o CPF.');
      return;
    }
    
    const toastId = toast.loading('Verificando CPF...');
    const { data, error } = await supabase.rpc('check_cpf_exists', {
      p_empresa_id: currentEmpresa.id,
      p_cpf: cpf,
    });
    toast.dismiss(toastId);

    if (error) {
      toast.error('Falha ao verificar CPF.');
    } else if (data) {
      toast.error('Este CPF já está cadastrado para esta empresa.');
    } else {
      toast.success('CPF válido e disponível.');
    }
  }, [currentEmpresa]);

  const handleCnpjBlur = useCallback(async (cnpj: string) => {
    if (!cnpj) return;

    if (!isValidCNPJ(cnpj)) {
      toast.error('O CNPJ informado é inválido.');
      return;
    }

    if (!currentEmpresa?.id) {
      toast.error('Nenhuma empresa selecionada para verificar o CNPJ.');
      return;
    }

    const toastId = toast.loading('Verificando CNPJ...');
    const { data, error } = await supabase.rpc('check_cnpj_exists', {
      p_empresa_id: currentEmpresa.id,
      p_cnpj: cnpj,
    });
    toast.dismiss(toastId);

    if (error) {
      toast.error('Falha ao verificar CNPJ.');
      return;
    }
    if (data) {
      toast.error('Este CNPJ já está cadastrado para esta empresa.');
      return;
    }
    
    // Se não existe, busca os dados na API externa
    onBuscaCnpj(cnpj);

  }, [currentEmpresa, onBuscaCnpj]);

  return (
    <section>
      <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Informações Gerais</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Controller
          name="tipoPessoa"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Tipo de Pessoa *">
              <select className="glass-input" {...field} value={field.value || ''}>
                <option value={TipoPessoa.PJ}>Pessoa Jurídica</option>
                <option value={TipoPessoa.PF}>Pessoa Física</option>
              </select>
            </InputWrapper>
          )}
        />
        <Controller
          name="tipoContato"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Tipo de Contato *">
              <select className="glass-input" {...field} value={field.value || ''}>
                {Object.values(TipoContato).map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </InputWrapper>
          )}
        />
        <Controller name="cnpjCpf" control={control} render={({ field, fieldState }) => (
          <InputWrapper label={tipoPessoa === TipoPessoa.PF ? "CPF *" : "CNPJ *"} error={fieldState.error?.message}>
            <IMaskInput 
              mask={tipoPessoa === TipoPessoa.PF ? '000.000.000-00' : '00.000.000/0000-00'} 
              value={field.value || ''} 
              onAccept={field.onChange}
              onBlur={() => {
                if (tipoPessoa === TipoPessoa.PJ && field.value) {
                  handleCnpjBlur(field.value);
                }
                if (tipoPessoa === TipoPessoa.PF && field.value) {
                  handleCpfBlur(field.value);
                }
              }}
              className="glass-input" 
            />
          </InputWrapper>
        )} />
        
        <div className="lg:col-span-2">
            <Controller name="nomeRazaoSocial" control={control} render={({ field, fieldState }) => (
              <InputWrapper label={tipoPessoa === TipoPessoa.PF ? "Nome Completo *" : "Razão Social *"} error={fieldState.error?.message}>
                <GlassInput {...field} maxLength={120} />
              </InputWrapper>
            )} />
        </div>
        <Controller name="fantasia" control={control} render={({ field }) => (
          <InputWrapper label="Nome Fantasia / Apelido">
            <GlassInput {...field} maxLength={60} />
          </InputWrapper>
        )} />
        
        <AnimatePresence mode="wait">
          {tipoPessoa === TipoPessoa.PJ ? (
            <motion.div key="pj-fields" {...motionProps} className="contents">
              <Controller name="inscricaoEstadual" control={control} render={({ field }) => (
                <InputWrapper label="Inscrição Estadual">
                  <GlassInput {...field} maxLength={20} />
                </InputWrapper>
              )} />
              <Controller name="inscricaoMunicipal" control={control} render={({ field }) => (
                <InputWrapper label="Inscrição Municipal">
                  <GlassInput {...field} maxLength={20} />
                </InputWrapper>
              )} />
            </motion.div>
          ) : (
            <motion.div key="pf-fields" {...motionProps} className="contents">
              <Controller name="rg" control={control} render={({ field }) => (
                <InputWrapper label="RG">
                  <GlassInput {...field} maxLength={20} />
                </InputWrapper>
              )} />
              <Controller name="rnm" control={control} render={({ field }) => (
                <InputWrapper label="RNM (Estrangeiro)">
                  <GlassInput {...field} maxLength={20} />
                </InputWrapper>
              )} />
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </section>
  );
};
