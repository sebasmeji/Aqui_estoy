
from fastapi import FastAPI
from routers.usuarios import router as usuarios_router

app = FastAPI(title="API AquiEstoy")

app.include_router(usuarios_router)


@app.get("/")
def inicio():
    return {"mensaje": "API AquiEstoy funcionando"}
