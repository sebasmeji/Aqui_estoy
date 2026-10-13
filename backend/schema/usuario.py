
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from typing import Literal


class UsuarioCrear(BaseModel):
    nombres: str = Field(min_length=1, max_length=80)
    apellidos: str = Field(min_length=1, max_length=80)
    tipo_documento: Literal["CC", "TI", "CE", "PASAPORTE", "OTRO"] | None = None
    documento_identidad: str | None = Field(default=None, max_length=20)
    fecha_nacimiento: date | None = None
    telefono: str | None = Field(default=None, max_length=20)
    correo: EmailStr
    contrasena: str = Field(min_length=8, max_length=128)


class UsuarioActualizar(BaseModel):
    nombres: str | None = Field(default=None, max_length=80)
    apellidos: str | None = Field(default=None, max_length=80)
    tipo_documento: Literal["CC", "TI", "CE", "PASAPORTE", "OTRO"] | None = None
    documento_identidad: str | None = Field(default=None, max_length=20)
    fecha_nacimiento: date | None = None
    telefono: str | None = Field(default=None, max_length=20)
    correo: EmailStr | None = None
    estado: Literal["activo", "inactivo", "bloqueado"] | None = None


class UsuarioRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombres: str
    apellidos: str
    tipo_documento: str | None
    documento_identidad: str | None
    fecha_nacimiento: date | None
    telefono: str | None
    correo: EmailStr
    estado: str
    ultimo_acceso: datetime | None
    creado_en: datetime
    actualizado_en: datetime
