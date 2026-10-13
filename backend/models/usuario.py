
from sqlalchemy import (
    BigInteger,
    String,
    Date,
    DateTime,
    Enum,
    text
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Usuario(Base):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(
        BigInteger(),
        primary_key=True,
        autoincrement=True
    )

    nombres: Mapped[str] = mapped_column(String(80), nullable=False)
    apellidos: Mapped[str] = mapped_column(String(80), nullable=False)

    tipo_documento: Mapped[str | None] = mapped_column(
        Enum("CC", "TI", "CE", "PASAPORTE", "OTRO"),
        nullable=True
    )

    documento_identidad: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True
    )

    fecha_nacimiento: Mapped[Date | None] = mapped_column(
        Date,
        nullable=True
    )

    telefono: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True
    )

    correo: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
        unique=True
    )

    contrasena_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    estado: Mapped[str] = mapped_column(
        Enum("activo", "inactivo", "bloqueado"),
        nullable=False,
        server_default=text("'activo'")
    )

    ultimo_acceso: Mapped[DateTime | None] = mapped_column(
        DateTime,
        nullable=True
    )

    creado_en: Mapped[DateTime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP")
    )

    actualizado_en: Mapped[DateTime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        server_onupdate=text("CURRENT_TIMESTAMP")
    )
