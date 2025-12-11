import { useState } from 'react'
import './ResponseView.css'

interface ResponseViewProps {
  response: string
  onNewCapture: () => void
}

export function ResponseView({ response, onNewCapture }: ResponseViewProps) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(response)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="response-view">
      <div className="response-content">
        <pre className="response-text">{response}</pre>
      </div>

      <div className="response-actions">
        <button onClick={onNewCapture} className="btn btn-secondary">
          New Capture
        </button>
        <button onClick={handleCopy} className="btn btn-primary">
          {copied ? 'Copied!' : 'Copy'}
        </button>
      </div>
    </div>
  )
}
