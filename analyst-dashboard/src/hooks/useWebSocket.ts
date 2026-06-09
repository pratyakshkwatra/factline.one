import { useEffect, useRef } from 'react'
import { useQueryClient } from '@tanstack/react-query'

export function useWebSocket(url: string) {
  const queryClient = useQueryClient()
  const ws = useRef<WebSocket | null>(null)

  useEffect(() => {
    ws.current = new WebSocket(url)

    ws.current.onopen = () => {
      console.log('WebSocket Connected')
    }

    ws.current.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        if (data.type === 'update') {
          // Invalidate relevant queries when backend broadcasts an update
          queryClient.invalidateQueries({ queryKey: ['candidates'] })
          queryClient.invalidateQueries({ queryKey: ['investigations'] })
          queryClient.invalidateQueries({ queryKey: ['reports'] })
          queryClient.invalidateQueries({ queryKey: ['evidence'] })
        }
      } catch (e) {
        // Fallback for non-JSON or older string messages
        if (event.data === 'update') {
          queryClient.invalidateQueries()
        }
      }
    }

    ws.current.onclose = () => {
      console.log('WebSocket Disconnected')
      // Potentially add reconnection logic here
    }

    return () => {
      ws.current?.close()
    }
  }, [url, queryClient])

  return ws.current
}
