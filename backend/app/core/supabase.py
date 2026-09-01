# backend/app/core/supabase.py
import os
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client, Client

# Load .env from backend directory if present
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)
load_dotenv()  # also load from cwd if any

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = (
    os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    or os.getenv("SUPABASE_KEY")
    or os.getenv("SUPABASE_ANON_KEY")
)

if not SUPABASE_URL:
    raise RuntimeError("Missing SUPABASE_URL environment variable.")

if not SUPABASE_SERVICE_ROLE_KEY:
    raise RuntimeError(
        "Missing SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_KEY / SUPABASE_ANON_KEY) environment variable."
    )

# Single reusable client instance
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

def get_supabase() -> Client:
    return supabase