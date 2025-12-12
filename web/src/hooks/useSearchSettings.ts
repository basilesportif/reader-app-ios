import { useState, useCallback } from 'react'

const STORAGE_KEY_SEARCH_ENABLED = 'reader-app-search-enabled'
const STORAGE_KEY_RESULTS_PER_QUERY = 'reader-app-search-results-per-query'

export function useSearchSettings() {
  const [searchEnabled, setSearchEnabledState] = useState<boolean>(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY_SEARCH_ENABLED)
      return stored !== null ? stored === 'true' : true // default: true
    } catch (e) {
      console.error('Failed to load searchEnabled:', e)
      return true
    }
  })

  const [searchResultsPerQuery, setSearchResultsPerQueryState] = useState<number>(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY_RESULTS_PER_QUERY)
      if (stored !== null) {
        const value = parseInt(stored, 10)
        return isNaN(value) ? 5 : Math.min(10, Math.max(1, value))
      }
    } catch (e) {
      console.error('Failed to load searchResultsPerQuery:', e)
    }
    return 5 // default: 5
  })

  const setSearchEnabled = useCallback((enabled: boolean) => {
    setSearchEnabledState(enabled)
    try {
      localStorage.setItem(STORAGE_KEY_SEARCH_ENABLED, String(enabled))
    } catch (e) {
      console.error('Failed to save searchEnabled:', e)
    }
  }, [])

  const setSearchResultsPerQuery = useCallback((count: number) => {
    const value = Math.min(10, Math.max(1, count))
    setSearchResultsPerQueryState(value)
    try {
      localStorage.setItem(STORAGE_KEY_RESULTS_PER_QUERY, String(value))
    } catch (e) {
      console.error('Failed to save searchResultsPerQuery:', e)
    }
  }, [])

  return {
    searchEnabled,
    searchResultsPerQuery,
    setSearchEnabled,
    setSearchResultsPerQuery,
  }
}
