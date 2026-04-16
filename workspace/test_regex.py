import re

text = """### Part 2: SEARCH/REPLACE blocks

```python
<<<<<<< SEARCH
    docs = load_docs(Path("."))
=======
    folder_path = Path(".")
    docs = load_docs(folder_path)
>>>>>>> REPLACE
```
"""

pattern = r"```(?:\w+)?\n(.*?)```"
blocks = re.findall(pattern, text, re.DOTALL)
print('Blocks found:', len(blocks))
for b in blocks:
    print('---')
    print(repr(b[:200]))
