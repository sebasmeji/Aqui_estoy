
from sqlalchemy import select
from sqlalchemy.orm import Session
from pwdlib import PasswordHash

from models.usuario import Usuario

# Configurar el algoritmo seguro para las contraseñas
password_hash = PasswordHash.recommended()


def crear_usuario(db: Session, datos: dict):
    # Convertir la contraseña original en un hash
    contrasena_hash = password_hash.hash(datos.pop("contrasena"))

    # Crear el usuario con los datos recibidos
    usuario = Usuario(
        **datos,
        contrasena_hash=contrasena_hash
    )

    db.add(usuario)
    db.commit()
    db.refresh(usuario)

    return usuario


def consultar_usuarios(db: Session):
    consulta = select(Usuario).order_by(Usuario.id)
    return db.scalars(consulta).all()


def consultar_usuario(db: Session, usuario_id: int):
    consulta = select(Usuario).where(Usuario.id == usuario_id)
    return db.scalar(consulta)


def actualizar_usuario(db: Session, usuario: Usuario, cambios: dict):
    for campo, valor in cambios.items():
        setattr(usuario, campo, valor)

    db.commit()
    db.refresh(usuario)

    return usuario


def eliminar_usuario(db: Session, usuario: Usuario):
    db.delete(usuario)
    db.commit()
