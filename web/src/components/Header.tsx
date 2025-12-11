import { Provider, Model, modelsByProvider } from '../services/api'
import './Header.css'

interface HeaderProps {
  provider: Provider
  model: Model
  onProviderChange: (provider: Provider) => void
  onModelChange: (model: Model) => void
  onHistoryClick: () => void
  historyCount: number
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
}: HeaderProps) {
  const models = modelsByProvider[provider]

  return (
    <header className="header">
      <h1 className="header-title">Reader</h1>
      <div className="header-actions">
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
