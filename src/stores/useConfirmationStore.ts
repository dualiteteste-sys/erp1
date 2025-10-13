import { create } from 'zustand';

interface ConfirmationState {
  isOpen: boolean;
  title: string;
  message: string;
  onConfirm: () => void;
  show: (title: string, message: string, onConfirm: () => void) => void;
  hide: () => void;
}

export const useConfirmationStore = create<ConfirmationState>((set) => ({
  isOpen: false,
  title: '',
  message: '',
  onConfirm: () => {},
  show: (title, message, onConfirm) => set({ isOpen: true, title, message, onConfirm }),
  hide: () => set({ isOpen: false }),
}));
