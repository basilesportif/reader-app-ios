import { useState, useCallback } from 'react'
import { Provider, Model, defaultModels, modelsByProvider } from '../services/api'

const STORAGE_KEY_PROVIDER = 'reader-app-default-provider'
const STORAGE_KEY_MODEL = 'reader-app-default-model'

function isValidProvider(value: string): value is Provider {
  return ['claude', 'openai', 'gemini'].includes(value)
}

function isValidModelForProvider(model: string, provider: Provider): boolean {
  return modelsByProvider[provider].some(m => m.value === model)
}

export function useModelDefaults() {
  const [provider, setProviderState] = useState<Provider>(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY_PROVIDER)
      if (stored && isValidProvider(stored)) {
        return stored
      }
    } catch (e) {
      console.error('Failed to load provider:', e)
    }
    return 'claude'
  })

  const [model, setModelState] = useState<Model>(() => {
    try {
      const storedProvider = localStorage.getItem(STORAGE_KEY_PROVIDER)
      const storedModel = localStorage.getItem(STORAGE_KEY_MODEL)
      const validProvider = storedProvider && isValidProvider(storedProvider) ? storedProvider : 'claude'

      if (storedModel && isValidModelForProvider(storedModel, validProvider)) {
        return storedModel as Model
      }
    } catch (e) {
      console.error('Failed to load model:', e)
    }
    return defaultModels[provider]
  })

  // Persist provider changes
  const setProvider = useCallback((newProvider: Provider) => {
    setProviderState(newProvider)
    localStorage.setItem(STORAGE_KEY_PROVIDER, newProvider)
    // Reset model to default for new provider
    const newModel = defaultModels[newProvider]
    setModelState(newModel)
    localStorage.setItem(STORAGE_KEY_MODEL, newModel)
  }, [])

  // Persist model changes
  const setModel = useCallback((newModel: Model) => {
    setModelState(newModel)
    localStorage.setItem(STORAGE_KEY_MODEL, newModel)
  }, [])

  return { provider, model, setProvider, setModel }
}
