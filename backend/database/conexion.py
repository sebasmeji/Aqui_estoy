
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import sessionmaker

# Cargar las variables del archivo .env
load_dotenv()

# Preparar la URL de conexión
url_conexion = URL.create(
    drivername="mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST", "localhost"),
    port=int(os.getenv("DB_PORT", "3306")),
    database=os.getenv("DB_NAME", "aqui_estoy")
)

# Crear el motor de conexión
motor = create_engine(
    url_conexion,
    pool_pre_ping=True
)

# Crear sesiones para consultar la base de datos
SesionLocal = sessionmaker(
    bind=motor,
    autoflush=False,
    expire_on_commit=False
)


# Proporcionar una sesión a cada solicitud
def obtener_db():
    db = SesionLocal()
    try:
        yield db
    finally:
        db.close()
