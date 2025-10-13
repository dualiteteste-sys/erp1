import React from 'react';
import { UseFormSetValue } from 'react-hook-form';
import { AttachmentManager } from '../../ui/AttachmentManager';
import { ClienteAnexo } from '../../../types';
import { ClienteFornecedorFormData } from '../../../schemas/clienteSchema';
import { useService } from '../../../hooks/useService';

interface AnexosTabProps {
  attachments: (File | ClienteAnexo)[];
  setValue: UseFormSetValue<ClienteFornecedorFormData>;
}

export const AnexosTab: React.FC<AnexosTabProps> = ({ attachments, setValue }) => {
  const clienteService = useService('cliente');

  return (
    <AttachmentManager
      attachments={attachments}
      onAttachmentsChange={(newAttachments) => setValue('anexos', newAttachments, { shouldDirty: true })}
      getPublicUrlService={clienteService.getAnexoPublicUrl}
    />
  );
};
