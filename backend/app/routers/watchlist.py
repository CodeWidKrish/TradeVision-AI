from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.auth import get_current_user
from app.database import get_db
from app.models.user import User
from app.models.watchlist import Watchlist
from app.schemas.watchlist import WatchlistCreate, WatchlistResponse

router = APIRouter(prefix="/watchlist", tags=["watchlist"])

@router.get("", response_model=List[WatchlistResponse])
@router.get("/", response_model=List[WatchlistResponse], include_in_schema=False)
async def get_user_watchlist(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve the authenticated user's watchlist."""
    result = await db.execute(
        select(Watchlist).where(Watchlist.user_id == current_user.id)
    )
    items = result.scalars().all()
    return items

@router.post("", response_model=WatchlistResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=WatchlistResponse, status_code=status.HTTP_201_CREATED, include_in_schema=False)
async def add_to_watchlist(
    data: WatchlistCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add a stock symbol to the authenticated user's watchlist."""
    symbol = data.symbol.strip().upper()
    if not symbol:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Symbol cannot be empty"
        )

    # Check for duplicate symbol in current user's watchlist
    result = await db.execute(
        select(Watchlist).where(
            Watchlist.user_id == current_user.id,
            Watchlist.symbol == symbol
        )
    )
    existing_item = result.scalars().first()
    if existing_item:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Symbol '{symbol}' is already in your watchlist"
        )

    new_item = Watchlist(
        user_id=current_user.id,
        symbol=symbol
    )
    db.add(new_item)
    await db.commit()
    await db.refresh(new_item)

    return new_item

@router.delete("/{symbol}")
async def remove_from_watchlist(
    symbol: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Remove a stock symbol from the authenticated user's watchlist."""
    normalized_symbol = symbol.strip().upper()
    if not normalized_symbol:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Symbol parameter cannot be empty"
        )

    result = await db.execute(
        select(Watchlist).where(
            Watchlist.user_id == current_user.id,
            Watchlist.symbol == normalized_symbol
        )
    )
    item = result.scalars().first()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Symbol '{normalized_symbol}' not found in your watchlist"
        )

    await db.delete(item)
    await db.commit()

    return {"message": f"Symbol '{normalized_symbol}' removed from watchlist"}
