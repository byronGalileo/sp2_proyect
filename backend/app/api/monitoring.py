# app/api/monitoring.py
from fastapi import APIRouter

router = APIRouter()

@router.post("/execute/{connection_id}")
async def execute_monitoring(connection_id: int):
    return {"message": f"Execute monitoring for connection {connection_id} - coming soon"}

@router.get("/results/{connection_id}")
async def get_monitoring_results(connection_id: int):
    return {"message": f"Get results for connection {connection_id} - coming soon"}