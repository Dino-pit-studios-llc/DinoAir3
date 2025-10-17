"""Calendar Events API Router"""

from __future__ import annotations

import logging
from typing import Any

from database.appointments_db import AppointmentsDatabase
from database.initialize_db import DatabaseManager
from fastapi import APIRouter, HTTPException, status
from models.calendar_event import CalendarEvent
from pydantic import BaseModel, Field

log = logging.getLogger("api.routes.calendar")

router = APIRouter(prefix="/api/v1/calendar", tags=["calendar"])

# Initialize database
_db_manager = DatabaseManager()
_appointments_db = AppointmentsDatabase(_db_manager)


# Request/Response Models
class CalendarEventCreateRequest(BaseModel):
    """Request model for creating calendar events"""

    title: str = Field(..., min_length=1, max_length=500)
    description: str = Field(default="")
    event_type: str = Field(default="event")  # meeting, task, reminder, event
    status: str = Field(default="scheduled")  # scheduled, completed, cancelled
    event_date: str = Field(...)  # ISO date string
    start_time: str | None = Field(default=None)  # ISO datetime string
    end_time: str | None = Field(default=None)  # ISO datetime string
    all_day: bool = Field(default=False)
    location: str | None = Field(default=None)
    participants: list[str] = Field(default_factory=list)
    project_id: str | None = Field(default=None)
    chat_session_id: str | None = Field(default=None)
    recurrence_pattern: str | None = Field(default=None)
    recurrence_rule: str | None = Field(default=None)
    reminder_minutes_before: int | None = Field(default=None)
    tags: list[str] = Field(default_factory=list)
    notes: str | None = Field(default=None)
    color: str | None = Field(default=None)
    metadata: dict[str, Any] = Field(default_factory=dict)


class CalendarEventUpdateRequest(BaseModel):
    """Request model for updating calendar events"""

    title: str | None = Field(default=None, min_length=1, max_length=500)
    description: str | None = Field(default=None)
    event_type: str | None = Field(default=None)
    status: str | None = Field(default=None)
    event_date: str | None = Field(default=None)
    start_time: str | None = Field(default=None)
    end_time: str | None = Field(default=None)
    all_day: bool | None = Field(default=None)
    location: str | None = Field(default=None)
    participants: list[str] | None = Field(default=None)
    project_id: str | None = Field(default=None)
    chat_session_id: str | None = Field(default=None)
    recurrence_pattern: str | None = Field(default=None)
    recurrence_rule: str | None = Field(default=None)
    reminder_minutes_before: int | None = Field(default=None)
    tags: list[str] | None = Field(default=None)
    notes: str | None = Field(default=None)
    color: str | None = Field(default=None)
    metadata: dict[str, Any] | None = Field(default=None)


class CalendarEventResponse(BaseModel):
    """Response model for calendar events"""

    id: str
    title: str
    description: str
    event_type: str
    status: str
    event_date: str
    start_time: str | None
    end_time: str | None
    all_day: bool
    location: str | None
    participants: list[str]
    project_id: str | None
    chat_session_id: str | None
    recurrence_pattern: str | None
    recurrence_rule: str | None
    reminder_minutes_before: int | None
    reminder_sent: bool
    tags: list[str]
    notes: str | None
    color: str | None
    metadata: dict[str, Any] | None
    created_at: str
    updated_at: str
    completed_at: str | None


def _event_to_response(event: CalendarEvent) -> CalendarEventResponse:
    """Convert CalendarEvent model to API response"""
    event_dict = event.to_dict()
    return CalendarEventResponse(
        id=event_dict["id"],
        title=event_dict["title"],
        description=event_dict["description"],
        event_type=event_dict["event_type"],
        status=event_dict["status"],
        event_date=event_dict["event_date"],
        start_time=event_dict.get("start_time"),
        end_time=event_dict.get("end_time"),
        all_day=event_dict["all_day"],
        location=event_dict.get("location"),
        participants=event_dict.get("participants", []),
        project_id=event_dict.get("project_id"),
        chat_session_id=event_dict.get("chat_session_id"),
        recurrence_pattern=event_dict.get("recurrence_pattern"),
        recurrence_rule=event_dict.get("recurrence_rule"),
        reminder_minutes_before=event_dict.get("reminder_minutes_before"),
        reminder_sent=event_dict.get("reminder_sent", False),
        tags=event_dict.get("tags", []),
        notes=event_dict.get("notes"),
        color=event_dict.get("color"),
        metadata=event_dict.get("metadata"),
        created_at=event_dict["created_at"],
        updated_at=event_dict["updated_at"],
        completed_at=event_dict.get("completed_at"),
    )


@router.post(
    "", response_model=CalendarEventResponse, status_code=status.HTTP_201_CREATED
)
def create_calendar_event(event_data: CalendarEventCreateRequest):
    """Create a new calendar event"""
    try:
        # Create CalendarEvent instance
        event = CalendarEvent.from_dict(event_data.model_dump())

        result = _appointments_db.create_event(event)

        if not result.get("success"):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result.get("error", "Failed to create calendar event"),
            )

        # Fetch the created event
        created_event = _appointments_db.get_event(result["id"])
        if not created_event:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Event created but could not be retrieved",
            )

        return _event_to_response(created_event)

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Error creating calendar event")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        ) from e


@router.get("", response_model=list[CalendarEventResponse])
def list_calendar_events(
    start_date: str | None = None,
    end_date: str | None = None,
    event_type: str | None = None,
    status_filter: str | None = None,
):
    """List calendar events with optional filters"""
    try:
        # Get events based on filters
        if start_date and end_date:
            events = _appointments_db.get_events_by_date_range(start_date, end_date)
        elif start_date:
            events = _appointments_db.get_events_for_date(start_date)
        else:
            events = _appointments_db.get_all_events()

        # Additional filtering
        if event_type:
            events = [e for e in events if e.event_type == event_type]

        if status_filter:
            events = [e for e in events if e.status == status_filter]

        return [_event_to_response(event) for event in events]

    except Exception as e:
        log.exception("Error listing calendar events")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        ) from e


@router.get("/{event_id}", response_model=CalendarEventResponse)
def get_calendar_event(event_id: str):
    """Get a specific calendar event by ID"""
    try:
        event = _appointments_db.get_event(event_id)

        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Calendar event with ID {event_id} not found",
            )

        return _event_to_response(event)

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Error fetching calendar event %s", event_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        ) from e


@router.put("/{event_id}", response_model=CalendarEventResponse)
def update_calendar_event(event_id: str, update_data: CalendarEventUpdateRequest):
    """Update an existing calendar event"""
    try:
        # Check if event exists
        existing_event = _appointments_db.get_event(event_id)
        if not existing_event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Calendar event with ID {event_id} not found",
            )

        # Filter out None values
        updates = {k: v for k, v in update_data.model_dump().items() if v is not None}

        if not updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No valid fields to update",
            )

        success = _appointments_db.update_event(event_id, updates)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update calendar event",
            )

        # Fetch updated event
        updated_event = _appointments_db.get_event(event_id)
        if not updated_event:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Event updated but could not be retrieved",
            )

        return _event_to_response(updated_event)

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Error updating calendar event %s", event_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        ) from e


@router.delete("/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_calendar_event(event_id: str):
    """Delete a calendar event"""
    try:
        # Check if event exists
        existing_event = _appointments_db.get_event(event_id)
        if not existing_event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Calendar event with ID {event_id} not found",
            )

        success = _appointments_db.delete_event(event_id)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete calendar event",
            )

        return None

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Error deleting calendar event %s", event_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        ) from e
