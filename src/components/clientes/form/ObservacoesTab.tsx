import React from 'react';
import { UseFormRegister } from 'react-hook-form';
import { ClienteFornecedorFormData } from '../../../schemas/clienteSchema';
import { InputWrapper } from '../../ui/InputWrapper';

interface ObservacoesTabProps {
  register: UseFormRegister<ClienteFornecedorFormData>;
}

export const ObservacoesTab: React.FC<ObservacoesTabProps> = ({ register }) => {
  return (
    <InputWrapper label="Observações Gerais">
      <textarea
        {...register('observacoes')}
        className="glass-input w-full h-64 resize-y"
        placeholder="Adicione qualquer observação relevante sobre este contato..."
      />
    </InputWrapper>
  );
};
