import sqlalchemy
import getpass
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# Datos de conexión a MySQL
usuario = input("Usuario de MySQL: ")
contrasena = getpass.getpass("Contraseña de MySQL: ")

conexion = URL.create(
    drivername="mysql+pymysql",
    username=usuario,
    password=contrasena,
    host="localhost",
    port=3306,
    database="aqui_estoy"
)

try:
    motor = create_engine(conexion)

    with motor.connect() as conexion_db:
        resultado = conexion_db.execute(
            text("SELECT DATABASE(), VERSION()")
        )
        base, version = resultado.fetchone()

        print("Conexión exitosa.")
        print("Base de datos:", base)
        print("Versión de MySQL:", version)

    motor.dispose()

except Exception as error:
    print("No se pudo conectar a MySQL.")
    print("Detalle:", error)
