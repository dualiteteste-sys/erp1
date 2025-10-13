import React, { useCallback } from 'react';
import { Control, UseFormSetValue, UseFormWatch } from 'react-hook-form';
import axios from 'axios';
import toast from 'react-hot-toast';
import { useCep } from '../../../hooks/useCep';
import { ClienteFornecedorFormData } from '../../../schemas/clienteSchema';
import { InformacoesGeraisSection } from './sections/InformacoesGeraisSection';
import { EnderecoSection } from './sections/EnderecoSection';
import { ContatoPrincipalSection } from './sections/ContatoPrincipalSection';

interface DadosGeraisTabProps {
  control: Control<ClienteFornecedorFormData>;
  watch: UseFormWatch<ClienteFornecedorFormData>;
  setValue: UseFormSetValue<ClienteFornecedorFormData>;
}

export const DadosGeraisTab: React.FC<DadosGeraisTabProps> = ({ control, watch, setValue }) => {
  const { handleBuscaCep } = useCep(setValue);

  const handleBuscaCnpj = useCallback(async (cnpj: string) => {
    const cleanCnpj = cnpj.replace(/\D/g, '');
    if (cleanCnpj.length !== 14) return;

    const toastId = toast.loading('Buscando dados do CNPJ...');
    try {
      const { data } = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${cleanCnpj}`);
      
      setValue('nomeRazaoSocial', data.razao_social || '', { shouldValidate: true });
      setValue('fantasia', data.nome_fantasia || '', { shouldValidate: true });
      setValue('cep', data.cep || '', { shouldValidate: true });
      setValue('endereco', data.logradouro || '', { shouldValidate: true });
      setValue('numero', data.numero || '', { shouldValidate: true });
      setValue('complemento', data.complemento || '', { shouldValidate: true });
      setValue('bairro', data.bairro || '', { shouldValidate: true });
      setValue('municipio', data.municipio || '', { shouldValidate: true });
      setValue('uf', data.uf || '', { shouldValidate: true });
      setValue('email', data.email || '', { shouldValidate: true });
      setValue('telefone', data.ddd_telefone_1 || '', { shouldValidate: true });
      
      toast.success('Dados preenchidos com sucesso!', { id: toastId });
    } catch (error) {
      toast.error('Falha ao buscar dados do CNPJ. Verifique o número e tente novamente.', { id: toastId });
    }
  }, [setValue]);

  return (
    <div className="space-y-8">
      <InformacoesGeraisSection control={control} watch={watch} onBuscaCnpj={handleBuscaCnpj} />
      <EnderecoSection control={control} watch={watch} onBuscaCep={handleBuscaCep} />
      <ContatoPrincipalSection control={control} />
    </div>
  );
};
