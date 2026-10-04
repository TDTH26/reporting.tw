"""Print the OpenAPI spec: python -m uavr.openapi > openapi.json"""

import json

from .main import app

if __name__ == "__main__":
    print(json.dumps(app.openapi(), indent=2, ensure_ascii=False))
