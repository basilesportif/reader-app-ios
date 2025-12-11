import { Provider } from '../services/api'
import './Header.css'

interface HeaderProps {
  provider: Provider
  onProviderChange: (provider: Provider) => void
}

const providers: { value: Provider; label: string }[] = [
  { value: 'claude', label: 'Claude' },
  { value: 'openai', label: 'OpenAI' },
  { value: 'gemini', label: 'Gemini' },
]

export function Header({ provider, onProviderChange }: HeaderProps) {
  return (
    <header className="header">
      <h1 className="header-title">Reader</h1>
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
    </header>
  )
}
