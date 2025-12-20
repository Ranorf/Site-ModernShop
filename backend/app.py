from typing import List

from fastapi import Depends, FastAPI
from pydantic import BaseModel
from sqlalchemy.orm import Session

from . import models
from .database import Base, SessionLocal, engine

app = FastAPI(title="ModernShop API", version="1.0.0", description="Легкий бекенд для демонстрації каталогу")


class ProductOut(BaseModel):
    id: int
    name: str
    description: str
    price: float
    in_stock: bool
    accent: str

    class Config:
        orm_mode = True


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)
    seed_products()


def seed_products():
    sample = [
        {
            "id": 1,
            "name": "Лаконічний рюкзак",
            "description": "Водостійка тканина з відділенням для ноутбука та магнітними застібками.",
            "price": 3200,
            "accent": "#d92bd6",
            "in_stock": True,
        },
        {
            "id": 2,
            "name": "Смарт-годинник Urban",
            "description": "OLED-дисплей, NFC та тиждень автономності для міського ритму.",
            "price": 5800,
            "accent": "#a31fdc",
            "in_stock": True,
        },
        {
            "id": 3,
            "name": "Бездротові навушники",
            "description": "Шумозаглушення, 32 години роботи та магнітний кейс у графітовому кольорі.",
            "price": 4050,
            "accent": "#661f7c",
            "in_stock": True,
        },
    ]

    db = SessionLocal()
    try:
        for item in sample:
            exists = db.query(models.Product).filter(models.Product.id == item["id"]).first()
            if not exists:
                db.add(models.Product(**item))
        db.commit()
    finally:
        db.close()


@app.get("/products", response_model=List[ProductOut])
def list_products(db: Session = Depends(get_db)):
    return db.query(models.Product).all()


@app.get("/health")
def health():
    return {"status": "ok"}
