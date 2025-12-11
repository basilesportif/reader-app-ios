import { useState, useEffect, useCallback } from 'react'

export interface QueryHistoryItem {
  id: string
  timestamp: number
  prompt: string
  response: string
  provider: string
  imagePreview?: string // small base64 thumbnail
}

const STORAGE_KEY = 'reader-app-query-history'
const MAX_HISTORY_ITEMS = 50

export function useQueryHistory() {
  const [history, setHistory] = useState<QueryHistoryItem[]>([])

  // Load history from localStorage on mount
  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (stored) {
        setHistory(JSON.parse(stored))
      }
    } catch (e) {
      console.error('Failed to load query history:', e)
    }
  }, [])

  // Save history to localStorage when it changes
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(history))
    } catch (e) {
      console.error('Failed to save query history:', e)
    }
  }, [history])

  const addToHistory = useCallback((item: Omit<QueryHistoryItem, 'id' | 'timestamp'>) => {
    const newItem: QueryHistoryItem = {
      ...item,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
    }

    setHistory(prev => {
      const updated = [newItem, ...prev]
      // Keep only the most recent items
      return updated.slice(0, MAX_HISTORY_ITEMS)
    })
  }, [])

  const removeFromHistory = useCallback((id: string) => {
    setHistory(prev => prev.filter(item => item.id !== id))
  }, [])

  const clearHistory = useCallback(() => {
    setHistory([])
  }, [])

  return { history, addToHistory, removeFromHistory, clearHistory }
}

// Helper to create a small thumbnail from base64 image
export function createThumbnail(base64Image: string, maxSize = 100): Promise<string> {
  return new Promise((resolve) => {
    const img = new Image()
    img.onload = () => {
      const canvas = document.createElement('canvas')
      const scale = Math.min(maxSize / img.width, maxSize / img.height)
      canvas.width = img.width * scale
      canvas.height = img.height * scale

      const ctx = canvas.getContext('2d')
      if (ctx) {
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height)
        resolve(canvas.toDataURL('image/jpeg', 0.5).split(',')[1])
      } else {
        resolve('')
      }
    }
    img.onerror = () => resolve('')
    img.src = `data:image/jpeg;base64,${base64Image}`
  })
}
