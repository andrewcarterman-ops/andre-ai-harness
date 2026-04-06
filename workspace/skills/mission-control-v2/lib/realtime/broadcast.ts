// lib/realtime/broadcast.ts - Shared broadcast function for SSE

const clients = new Map<string, ReadableStreamDefaultController>();

export function addClient(clientId: string, controller: ReadableStreamDefaultController) {
  clients.set(clientId, controller);
}

export function removeClient(clientId: string) {
  clients.delete(clientId);
}

export function broadcast(data: any) {
  const message = `data: ${JSON.stringify(data)}\n\n`;
  const encoded = new TextEncoder().encode(message);
  
  clients.forEach((controller, clientId) => {
    try {
      controller.enqueue(encoded);
    } catch (e) {
      clients.delete(clientId);
    }
  });
}

export function broadcastToClient(clientId: string, data: any) {
  const controller = clients.get(clientId);
  if (controller) {
    const message = `data: ${JSON.stringify(data)}\n\n`;
    try {
      controller.enqueue(new TextEncoder().encode(message));
    } catch (e) {
      clients.delete(clientId);
    }
  }
}

export function getClientCount(): number {
  return clients.size;
}

export function getClients(): string[] {
  return Array.from(clients.keys());
}
