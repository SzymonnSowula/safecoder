# File Upload Security

## Rules

1. **Allow-list extensions and MIME types.** Block everything else.
2. **Verify file content.** Magic bytes are more reliable than extensions.
3. **Limit file size.** Both client-side and server-side.
4. **Rename files.** Use random IDs, never original filenames.
5. **Store outside web root.** Serve via controller or signed URL.
6. **Scan files.** Use antivirus or sandbox for untrusted uploads.
7. **Set correct Content-Type and Content-Disposition.** Force download for dangerous types.

## Example: Python + Flask

```python
import uuid
import magic
from pathlib import Path
from werkzeug.utils import secure_filename

ALLOWED_TYPES = {"image/png": ".png", "image/jpeg": ".jpg", "application/pdf": ".pdf"}
MAX_SIZE = 5 * 1024 * 1024
UPLOAD_DIR = Path("/var/uploads")

def upload_file(file, user_id):
    if file.content_length > MAX_SIZE:
        raise ValueError("File too large")

    blob = file.read(2048)
    mime = magic.from_buffer(blob, mime=True)
    if mime not in ALLOWED_TYPES:
        raise ValueError("Invalid file type")

    ext = ALLOWED_TYPES[mime]
    upload_id = str(uuid.uuid4())
    dest = UPLOAD_DIR / str(user_id) / f"{upload_id}{ext}"
    dest.parent.mkdir(parents=True, exist_ok=True)
    file.seek(0)
    file.save(dest)
    return upload_id
```

## Dangerous File Types

Block by default: `.exe`, `.bat`, `.cmd`, `.sh`, `.php`, `.jsp`, `.asp`, `.aspx`, `.dll`, `.so`, `.jar`.

## Serving Files

```python
from flask import send_file

def serve_file(user_id, upload_id):
    path = resolve_upload_path(user_id, upload_id)
    return send_file(path, as_attachment=True)
```

Set `Content-Disposition: attachment` to prevent browsers from executing files.
