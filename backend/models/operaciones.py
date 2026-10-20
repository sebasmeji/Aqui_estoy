
from sqlalchemy import select
from sqlalchemy.orm import Session

from models.usuario import Usuario


def crear_usuario(db: Session, datos: dict):
    usuario = Usuario(**datos)

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
