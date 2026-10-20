
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from typing import Literal


TipoDocumento = Literal["CC", "TI", "CE", "PASAPORTE", "OTRO"]
EstadoUsuario = Literal["activo", "inactivo", "bloqueado"]
Parentesco = Literal["madre", "padre", "hijo", "abuela", "otro"]


class UsuarioCrear(BaseModel):
    nombres: str = Field(min_length=1, max_length=80)
    apellidos: str = Field(min_length=1, max_length=80)
    tipo_documento: TipoDocumento | None = None
    documento_identidad: str | None = Field(default=None, max_length=20)
    telefono: str | None = Field(default=None, max_length=20)
    correo: EmailStr
    parentesco: Parentesco | None = None


class UsuarioActualizar(BaseModel):
    nombres: str | None = Field(default=None, min_length=1, max_length=80)
    apellidos: str | None = Field(default=None, min_length=1, max_length=80)
    tipo_documento: TipoDocumento | None = None
    documento_identidad: str | None = Field(default=None, max_length=20)
    telefono: str | None = Field(default=None, max_length=20)
    correo: EmailStr | None = None
    estado: EstadoUsuario | None = None
    parentesco: Parentesco | None = None


class UsuarioRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombres: str
    apellidos: str
    tipo_documento: str | None
    documento_identidad: str | None
    telefono: str | None
    correo: EmailStr
    estado: str
    parentesco: str | None
