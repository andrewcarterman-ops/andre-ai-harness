import sounddevice as sd

devices = sd.query_devices()
print("Verfuegbare Mikrofone:")
for i, d in enumerate(devices):
    if d['max_input_channels'] > 0:
        print(f"  {i}: {d['name']}")
        
default = sd.default.device[0]
print(f"\nStandard-Mikrofon: {default}")
if default is not None:
    print(f"Name: {devices[default]['name']}")
