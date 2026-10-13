
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database.conexion import obtener_db
from schema.usuario import UsuarioCrear, UsuarioRespuesta
from models.operaciones import crear_usuario

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])


@router.post(
    "/",
    response_model=UsuarioRespuesta,
    status_code=status.HTTP_201_CREATED
)
def registrar_usuario(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_db)
):
    try:
        # Obtener los datos validados
        datos_usuario = datos.model_dump()
        usuario = crear_usuario(db, datos_usuario)

        return usuario

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El correo o documento puede estar registrado."
        )
