from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.api.routes import compute
from backend.api.dependencies import start_core, stop_core

app = FastAPI(title="UniLab API", version="0.1.0")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(compute.router)

@app.on_event("startup")
async def startup_event():
    await start_core()

@app.on_event("shutdown")
async def shutdown_event():
    await stop_core()

@app.get("/")
async def root():
    return {"message": "UniLab API is running"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
