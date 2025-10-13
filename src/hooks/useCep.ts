import { useCallback } from 'react';
import axios from 'axios';
import toast from 'react-hot-toast';
import { UseFormSetValue } from 'react-hook-form';

export const useCep = <T extends Record<string, any>>(setValue: UseFormSetValue<T>) => {
  const handleBuscaCep = useCallback(async (cep: string, isCobranca: boolean = false) => {
    const cleanCep = cep.replace(/\D/g, '');
    if (cleanCep.length !== 8) return;

    const toastId = toast.loading('Buscando CEP...');
    try {
      const { data } = await axios.get(`https://viacep.com.br/ws/${cleanCep}/json/`);
      if (data.erro) {
        toast.error('CEP não encontrado.', { id: toastId });
        return;
      }
      
      if (isCobranca) {
        setValue('cobrCep' as any, data.cep);
        setValue('cobrEndereco' as any, data.logradouro);
        setValue('cobrBairro' as any, data.bairro);
        setValue('cobrMunicipio' as any, data.localidade);
        setValue('cobrUf' as any, data.uf);
      } else {
        // Suporta tanto o schema de Cliente (endereco, municipio) quanto o de Vendedor (logradouro, cidade)
        setValue('cep' as any, data.cep);
        setValue('endereco' as any, data.logradouro);
        setValue('logradouro' as any, data.logradouro);
        setValue('bairro' as any, data.bairro);
        setValue('municipio' as any, data.localidade);
        setValue('cidade' as any, data.localidade);
        setValue('uf' as any, data.uf);
      }
      toast.success('Endereço preenchido!', { id: toastId });
    } catch (error) {
      console.error("Erro ao buscar CEP:", error);
      toast.error('Falha ao buscar CEP.', { id: toastId });
    }
  }, [setValue]);

  return { handleBuscaCep };
};
