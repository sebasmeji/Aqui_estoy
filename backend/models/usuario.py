
from sqlalchemy import String, Enum
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Usuario(Base):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
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

    telefono: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True
    )

    correo: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
        unique=True
    )

    estado: Mapped[str] = mapped_column(
        Enum("activo", "inactivo", "bloqueado"),
        nullable=False,
        default="activo"
    )

    parentesco: Mapped[str | None] = mapped_column(
        Enum("madre", "padre", "hijo", "abuela", "otro"),
        nullable=True
    )
