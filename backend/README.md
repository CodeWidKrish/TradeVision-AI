# TradeVision AI Backend

This is the backend of the TradeVision AI project built with FastAPI.

## Project Structure

backend/
  app/
    main.py
    routers/
    services/
    schemas/
    utils/
  README.md
  requirements.txt

## Setup

1. Create and activate the virtual environment.
2. Install dependencies.
3. Run the server using Uvicorn.

## Run Commands

```bash
python -m venv venv
venv\Scripts\activate
pip install fastapi uvicorn python-dotenv pydantic
uvicorn app.main:app --reload
```

## API Routes

- `/` - root route
- `/health` - health check