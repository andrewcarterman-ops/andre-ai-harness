# Test 1: Guter Code (sollte BESTEHEN)
import torch
import torch.nn as nn
import torch.nn.functional as F

class GPT(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc = nn.Linear(768, 768)
    
    def forward(self, x):
        return self.fc(x)

# Legitime mathematische Operationen
x = torch.randn(10, 768)
model = GPT()
output = model(x)
loss = output.mean()

# Lokale Datei-Operation (in erlaubtem Pfad)
import os
path = os.path.join("~/.cache/autoresearch/", "test.txt")

print(f"Output shape: {output.shape}")
