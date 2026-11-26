import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { I18nManager, Platform } from 'react-native';
import { MMKV } from 'react-native-mmkv';
import { useTranslation, type TranslationKey } from '../utils/i18n';

interface LanguageContextValue {
  language: 'en' | 'ar';
  setLanguage: (lang: 'en' | 'ar') => void;
  t: (key: TranslationKey, replacements?: Record<string, string | number>) => string;
  isRTL: boolean;
}

const LanguageContext = createContext<LanguageContextValue | undefined>(undefined);
const LANGUAGE_STORAGE_KEY = 'wasel-language';

// Same MMKV instance used in index.js so both see the same value at startup.
const startupStorage = new MMKV({ id: 'wasel-startup' });

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [language, setLanguage] = useState<'en' | 'ar'>('ar');

  const value = useTranslation(language);

  useEffect(() => {
    let active = true;
    // MMKV is synchronous but can't be read before state is ready here;
    // try it first, fall back to AsyncStorage for existing installs.
    const mmkvLang = startupStorage.getString(LANGUAGE_STORAGE_KEY);
    if (mmkvLang === 'en' || mmkvLang === 'ar') {
      setLanguage(mmkvLang);
    } else {
      void AsyncStorage.getItem(LANGUAGE_STORAGE_KEY).then(stored => {
        if (active && (stored === 'en' || stored === 'ar')) {
          setLanguage(stored);
          // Migrate to MMKV for future cold starts.
          startupStorage.set(LANGUAGE_STORAGE_KEY, stored);
        }
      });
    }
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    const isRTL = language === 'ar';
    I18nManager.allowRTL(true);
    if (I18nManager.isRTL !== isRTL) I18nManager.forceRTL(isRTL);

    if (Platform.OS === 'web' && typeof document !== 'undefined') {
      document.documentElement.dir = isRTL ? 'rtl' : 'ltr';
      document.documentElement.lang = language;
    }
  }, [language]);

  const updateLanguage = useCallback((nextLanguage: 'en' | 'ar') => {
    setLanguage(nextLanguage);
    // AsyncStorage: read on subsequent cold starts (async fallback).
    void AsyncStorage.setItem(LANGUAGE_STORAGE_KEY, nextLanguage);
    // MMKV: read synchronously in index.js before first render.
    startupStorage.set(LANGUAGE_STORAGE_KEY, nextLanguage);
  }, []);

  return (
    <LanguageContext.Provider value={{ ...value, language, setLanguage: updateLanguage, isRTL: language === 'ar' }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  const fallback = useTranslation('ar');
  
  if (!context) {
    return { ...fallback, language: 'ar' as const, setLanguage: () => {}, isRTL: true };
  }
  return { ...context };
}
