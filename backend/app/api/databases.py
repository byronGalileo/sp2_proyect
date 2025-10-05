# app/api/databases.py
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def list_databases():
    return {"message": "List databases endpoint - coming soon"}

@router.post("/")
async def create_database():
    return {"message": "Create database endpoint - coming soon"}