import { Provider } from '../services/api'
import './Header.css'

interface HeaderProps {
  provider: Provider
  onProviderChange: (provider: Provider) => void
  onHistoryClick: () => void
  historyCount: number
}

const providers: { value: Provider; label: string }[] = [
  { value: 'claude', label: 'Claude' },
  { value: 'openai', label: 'OpenAI' },
  { value: 'gemini', label: 'Gemini' },
]

export function Header({ provider, onProviderChange, onHistoryClick, historyCount }: HeaderProps) {
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
      </div>
    </header>
  )
}
