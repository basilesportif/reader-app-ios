import { Provider, Model, modelsByProvider } from '../services/api'
import './Header.css'

interface HeaderProps {
  provider: Provider
  model: Model
  onProviderChange: (provider: Provider) => void
  onModelChange: (model: Model) => void
  onHistoryClick: () => void
  historyCount: number
  searchEnabled: boolean
  onSearchEnabledChange: (enabled: boolean) => void
  searchResultsPerQuery: number
  onSearchResultsPerQueryChange: (count: number) => void
}

const providers: { value: Provider; label: string }[] = [
  { value: 'claude', label: 'Claude' },
  { value: 'openai', label: 'OpenAI' },
  { value: 'gemini', label: 'Gemini' },
]

export function Header({
  provider,
  model,
  onProviderChange,
  onModelChange,
  onHistoryClick,
  historyCount,
  searchEnabled,
  onSearchEnabledChange,
  searchResultsPerQuery,
  onSearchResultsPerQueryChange,
}: HeaderProps) {
  const models = modelsByProvider[provider]

  return (
    <header className="header">
      <h1 className="header-title">Reader</h1>
      <div className="header-actions">
        <label className="search-toggle" title="Enable web search for image queries">
          <input
            type="checkbox"
            checked={searchEnabled}
            onChange={(e) => onSearchEnabledChange(e.target.checked)}
          />
          <span className="search-toggle-label">Search</span>
        </label>
        {searchEnabled && (
          <select
            className="search-results-select"
            value={searchResultsPerQuery}
            onChange={(e) => onSearchResultsPerQueryChange(parseInt(e.target.value, 10))}
            title="Results per search query"
          >
            {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((n) => (
              <option key={n} value={n}>
                {n}
              </option>
            ))}
          </select>
        )}
        <button className="history-button" onClick={onHistoryClick}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10" />
            <polyline points="12,6 12,12 16,14" />
          </svg>
          {historyCount > 0 && <span className="history-badge">{historyCount}</span>}
        </button>
        <select
          className="provider-select"
          value={provider}
          onChange={(e) => onProviderChange(e.target.value as Provider)}
        >
          {providers.map((p) => (
            <option key={p.value} value={p.value}>
              {p.label}
            </option>
          ))}
        </select>
        <select
          className="model-select"
          value={model}
          onChange={(e) => onModelChange(e.target.value as Model)}
        >
          {models.map((m) => (
            <option key={m.value} value={m.value}>
              {m.label}
            </option>
          ))}
        </select>
      </div>
    </header>
  )
}
