import { useState, useCallback } from 'react';
import axios from 'axios';
import toast from 'react-hot-toast';

interface NcmSuggestion {
  codigo: string;
  descricao: string;
}

export const useNcm = () => {
  const [suggestions, setSuggestions] = useState<NcmSuggestion[]>([]);
  const [description, setDescription] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const searchNcmByDescription = useCallback(async (query: string) => {
    if (query.length < 3) {
      setSuggestions([]);
      return;
    }
    setLoading(true);
    try {
      const { data } = await axios.get(`https://brasilapi.com.br/api/ncm/v1?search=${query}`);
      setSuggestions(data || []);
    } catch (error) {
      toast.error('Falha ao buscar sugestões de NCM.');
      setSuggestions([]);
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchNcmDescription = useCallback(async (code: string) => {
    if (!code || code.length < 8) {
        setDescription(null);
        return;
    }
    setLoading(true);
    try {
      const { data } = await axios.get(`https://brasilapi.com.br/api/ncm/v1/${code.replace(/\D/g, '')}`);
      setDescription(data.descricao || 'NCM não encontrado.');
    } catch (error) {
      setDescription('Falha ao buscar descrição do NCM.');
    } finally {
      setLoading(false);
    }
  }, []);

  const clearDescription = useCallback(() => {
    setDescription(null);
  }, []);

  return {
    suggestions,
    description,
    loading,
    searchNcmByDescription,
    fetchNcmDescription,
    clearDescription,
  };
};
