import React, { useState } from 'react';
import { Control, Controller, UseFormRegister, UseFormSetValue, FieldErrors } from 'react-hook-form';
import { VendedorFormData } from '../../../schemas/vendedorSchema';
import { InputWrapper } from '../../ui/InputWrapper';
import { GlassInput } from '../../ui/GlassInput';
import { Vendedor } from '../../../types';
import { Eye, EyeOff, KeyRound, RefreshCw } from 'lucide-react';
import { GlassButton } from '../../ui/GlassButton';
import { MultiSelect } from '../../ui/MultiSelect';
import toast from 'react-hot-toast';

const perfisContatoOptions = ['Cliente', 'Fornecedor', 'Funcionário', 'Transportador', 'Outro'];
const modulosOptions = [
  'Clientes', 'Comissões', 'CRM', 'Pedidos de Venda', 'PDV', 'Propostas Comerciais',
  'Relatório de Preços de Produtos', 'Cotação de fretes', 'Pode emitir cobranças',
  'Pode incluir produtos não cadastrados em pedidos de venda',
  'Pode incluir produtos não cadastrados em propostas comerciais',
  'Pode alterar senha de acesso',
];

interface AcessoPermissoesTabProps {
  control: Control<VendedorFormData>;
  register: UseFormRegister<VendedorFormData>;
  setValue: UseFormSetValue<VendedorFormData>;
  errors: FieldErrors<VendedorFormData>;
  vendedor?: Partial<Vendedor>;
}

export const AcessoPermissoesTab: React.FC<AcessoPermissoesTabProps> = ({ control, register, setValue, errors, vendedor }) => {
  const [showPassword, setShowPassword] = useState(false);
  const [isEditingPassword, setIsEditingPassword] = useState(!vendedor?.id);

  const generatePassword = () => {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()';
    let password = '';
    for (let i = 0; i < 12; i++) {
      password += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    setValue('senha', password, { shouldValidate: true });
    toast.success('Nova senha gerada!');
  };

  return (
    <section className="space-y-12">
      <div>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Dados de acesso</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <InputWrapper label="Depósito padrão"><GlassInput {...register('depositoPadrao')} /></InputWrapper>
          {!isEditingPassword && vendedor?.id ? (
            <InputWrapper label="Senha de acesso">
              <div className="flex items-center gap-2">
                <GlassInput value="•••••••• (Definida)" disabled />
                <GlassButton type="button" onClick={() => setIsEditingPassword(true)}>Alterar Senha</GlassButton>
              </div>
            </InputWrapper>
          ) : (
            <InputWrapper label="Senha de acesso" error={errors.senha?.message}>
              <div className="relative">
                <KeyRound className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                <GlassInput {...register('senha')} type={showPassword ? 'text' : 'password'} className="pl-10" />
                <div className="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1">
                  <button type="button" onClick={() => setShowPassword(p => !p)} className="p-1 text-gray-500 hover:text-gray-800">
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                  <GlassButton type="button" icon={RefreshCw} size="sm" onClick={generatePassword} />
                </div>
              </div>
            </InputWrapper>
          )}
        </div>
      </div>

      <div>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Restrições de acesso</h3>
        <div className="space-y-4">
          <Controller name="acessoRestritoHorario" control={control} render={({ field }) => (
            <label className="flex items-center gap-2 cursor-pointer"><input type="checkbox" className="form-checkbox" {...field} checked={field.value} /> Acesso restrito por horário</label>
          )} />
          <InputWrapper label="Acesso restrito por IP"><GlassInput {...register('acessoRestritoIp')} placeholder="Ex: 192.168.0.1, 10.0.0.0/24" /></InputWrapper>
        </div>
      </div>

      <div>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Permissões</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
          <Controller name="perfilContato" control={control} render={({ field }) => (
            <InputWrapper label="Pode acessar contatos com o perfil">
              <MultiSelect options={perfisContatoOptions} value={field.value || []} onChange={field.onChange} placeholder="Qualquer perfil de contato" />
            </InputWrapper>
          )} />
          <Controller name="permissoesModulos" control={control} render={({ field }) => (
            <InputWrapper label="Módulos que podem ser acessados pelo vendedor">
              <div className="grid grid-cols-2 gap-x-4 gap-y-2">
                {modulosOptions.map(mod => (
                  <label key={mod} className="flex items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      className="form-checkbox"
                      checked={field.value?.[mod] || false}
                      onChange={e => field.onChange({ ...field.value, [mod]: e.target.checked })}
                    />
                    {mod}
                  </label>
                ))}
              </div>
            </InputWrapper>
          )} />
        </div>
      </div>
    </section>
  );
};
