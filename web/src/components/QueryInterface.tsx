import { useState } from 'react'
import { Provider } from '../services/api'
import './QueryInterface.css'

interface QueryInterfaceProps {
  imageData: string
  onSubmit: (prompt: string) => void
  onRetake: () => void
  isLoading: boolean
  provider: Provider
}

export function QueryInterface({
  imageData,
  onSubmit,
  onRetake,
  isLoading,
  provider,
}: QueryInterfaceProps) {
  const [prompt, setPrompt] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (prompt.trim() && !isLoading) {
      onSubmit(prompt.trim())
    }
  }

  const imageSrc = 'data:image/jpeg;base64,' + imageData

  const providerNames: Record<Provider, string> = {
    claude: 'Claude',
    openai: 'OpenAI',
    gemini: 'Gemini',
  }

  return (
    <div className="query-interface">
      <div className="preview-container">
        <img src={imageSrc} alt="Captured" className="preview-image" />
      </div>

      <form onSubmit={handleSubmit} className="query-form">
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="Enter your question about this image..."
          className="query-input"
          rows={3}
          disabled={isLoading}
        />

        <div className="query-actions">
          <button
            type="button"
            onClick={onRetake}
            className="btn btn-secondary"
            disabled={isLoading}
          >
            Retake
          </button>
          <button
            type="submit"
            className="btn btn-primary"
            disabled={!prompt.trim() || isLoading}
          >
            {isLoading ? 'Querying ' + providerNames[provider] + '...' : 'Send'}
          </button>
        </div>
      </form>
    </div>
  )
}
