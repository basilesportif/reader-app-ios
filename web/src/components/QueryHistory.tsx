import { QueryHistoryItem } from '../hooks/useQueryHistory'
import './QueryHistory.css'

interface QueryHistoryProps {
  history: QueryHistoryItem[]
  onSelect: (item: QueryHistoryItem) => void
  onDelete: (id: string) => void
  onClear: () => void
}

export function QueryHistory({ history, onSelect, onDelete, onClear }: QueryHistoryProps) {
  if (history.length === 0) {
    return (
      <div className="query-history-empty">
        <p>No query history yet</p>
        <p className="hint">Your queries will appear here</p>
      </div>
    )
  }

  return (
    <div className="query-history">
      <div className="query-history-header">
        <h3>History</h3>
        <button onClick={onClear} className="clear-button">
          Clear all
        </button>
      </div>
      <div className="query-history-list">
        {history.map(item => (
          <div key={item.id} className="history-item" onClick={() => onSelect(item)}>
            <div className="history-item-content">
              {item.imagePreview && (
                <img
                  src={`data:image/jpeg;base64,${item.imagePreview}`}
                  alt=""
                  className="history-thumbnail"
                />
              )}
              <div className="history-item-text">
                <p className="history-prompt">{item.prompt}</p>
                <p className="history-meta">
                  <span className="history-provider">{item.model || item.provider}</span>
                  <span className="history-time">{formatTime(item.timestamp)}</span>
                </p>
              </div>
            </div>
            <button
              className="history-delete"
              onClick={(e) => {
                e.stopPropagation()
                onDelete(item.id)
              }}
            >
              ×
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}

function formatTime(timestamp: number): string {
  const now = Date.now()
  const diff = now - timestamp

  if (diff < 60000) return 'Just now'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`

  return new Date(timestamp).toLocaleDateString()
}
