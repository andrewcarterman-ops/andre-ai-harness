import { NextRequest } from 'next/server';
import { addClient, removeClient } from '@/lib/realtime/broadcast';

// Disable static generation for this route
export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

export async function GET(request: NextRequest) {
  const clientId = crypto.randomUUID();
  
  const stream = new ReadableStream({
    start(controller) {
      addClient(clientId, controller);
      
      // Send initial connection message
      const connectedMessage = `data: ${JSON.stringify({ 
        type: 'connected', 
        clientId 
      })}\n\n`;
      controller.enqueue(new TextEncoder().encode(connectedMessage));
      
      // Heartbeat every 30 seconds
      const heartbeat = setInterval(() => {
        try {
          const pingMessage = `data: ${JSON.stringify({ type: 'ping' })}\n\n`;
          controller.enqueue(new TextEncoder().encode(pingMessage));
        } catch (e) {
          clearInterval(heartbeat);
          removeClient(clientId);
        }
      }, 30000);
      
      request.signal.addEventListener('abort', () => {
        clearInterval(heartbeat);
        removeClient(clientId);
      });
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
}
