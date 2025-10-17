"""
Notes API routes for DinoAir.

Provides RESTful endpoints for managing notes with full CRUD operations.
"""

from __future__ import annotations

import logging
from typing import Any

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field, field_validator

from database.notes_service import NotesService
from models.note import Note

log = logging.getLogger("api.routes.notes")

router = APIRouter(prefix="/api/v1/notes", tags=["notes"])

# -----------------------
# Request/Response Models
# -----------------------


class NoteCreateRequest(BaseModel):
    """Request model for creating a new note."""

    title: str = Field(..., min_length=1, max_length=500)
    content: str = Field(..., max_length=100_000)
    tags: list[str] = Field(default_factory=list)
    project_id: str | None = Field(default=None, max_length=100)

    @field_validator("title", "content")
    @classmethod
    def _trim_strings(cls, v: str) -> str:
        """Trim whitespace from string fields."""
        return v.strip()

    @field_validator("tags")
    @classmethod
    def _validate_tags(cls, v: list[str]) -> list[str]:
        """Validate and clean tags."""
        if not v:
            return []
        # Remove empty tags and trim
        cleaned = [tag.strip() for tag in v if tag and tag.strip()]
        # Limit to 20 tags
        if len(cleaned) > 20:
            raise ValueError("Maximum 20 tags allowed")
        # Limit individual tag length
        for tag in cleaned:
            if len(tag) > 50:
                raise ValueError("Individual tags must be 50 characters or less")
        return cleaned


class NoteUpdateRequest(BaseModel):
    """Request model for updating an existing note."""

    title: str | None = Field(default=None, min_length=1, max_length=500)
    content: str | None = Field(default=None, max_length=100_000)
    tags: list[str] | None = Field(default=None)
    project_id: str | None = Field(default=None, max_length=100)

    @field_validator("title", "content")
    @classmethod
    def _trim_strings(cls, v: str | None) -> str | None:
        """Trim whitespace from string fields."""
        return v.strip() if v else None

    @field_validator("tags")
    @classmethod
    def _validate_tags(cls, v: list[str] | None) -> list[str] | None:
        """Validate and clean tags."""
        if v is None:
            return None
        if not v:
            return []
        cleaned = [tag.strip() for tag in v if tag and tag.strip()]
        if len(cleaned) > 20:
            raise ValueError("Maximum 20 tags allowed")
        for tag in cleaned:
            if len(tag) > 50:
                raise ValueError("Individual tags must be 50 characters or less")
        return cleaned


class NoteResponse(BaseModel):
    """Response model for a single note."""

    id: str
    title: str
    content: str
    tags: list[str]
    project_id: str | None
    created_at: str
    updated_at: str
    content_html: str | None = None

    @classmethod
    def from_note(cls, note: Note) -> NoteResponse:
        """Convert a Note model to response format."""
        return cls(
            id=note.id,
            title=note.title,
            tags=note.tags if isinstance(note.tags, list) else [],
            project_id=note.project_id,
            created_at=note.created_at or "",
            updated_at=note.updated_at or "",
            content_html=note.content_html,
        )


class NotesListResponse(BaseModel):
    """Response model for a list of notes."""

    notes: list[NoteResponse]
    total: int


class NoteCreatedResponse(BaseModel):
    """Response model for successful note creation."""

    id: str
    message: str
    warnings: list[str] = Field(default_factory=list)


class NoteUpdatedResponse(BaseModel):
    """Response model for successful note update."""

    message: str
    updated_fields: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)


class NoteDeletedResponse(BaseModel):
    """Response model for successful note deletion."""

    message: str


# -----------------------
# Helper Functions
# -----------------------


def _get_notes_service() -> NotesService:
    """Get an instance of the notes service."""
    return NotesService()


def _convert_note_to_response(note: Note) -> NoteResponse:
    """Convert a Note model to API response format."""
    return NoteResponse.from_note(note)


# -----------------------
# Route Handlers
# -----------------------


@router.post(
    "",
    response_model=NoteCreatedResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new note",
    responses={
        201: {"description": "Note created successfully"},
        400: {"description": "Invalid request data"},
        500: {"description": "Internal server error"},
    },
)
async def create_note(request: NoteCreateRequest) -> NoteCreatedResponse:
    """
    Create a new note with the provided title, content, and optional metadata.

    The note will be assigned a unique ID and timestamp automatically.
    """
    try:
        service = _get_notes_service()

        # Create Note model instance
        note = Note(
            title=request.title,
            content=request.content,
            tags=request.tags,
            project_id=request.project_id,
        )

        # Create note through service
        result = service.create_note(note)

        if not result.success:
            log.warning("Failed to create note: %s", result.error)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=result.error,
            )

        return NoteCreatedResponse(
            id=note.id,
            message="Note created successfully",
            warnings=result.warnings or [],
        )

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error creating note")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create note: {str(e)}",
        ) from e


@router.get(
    "",
    response_model=NotesListResponse,
    summary="List all notes",
    responses={
        200: {"description": "List of notes retrieved successfully"},
        500: {"description": "Internal server error"},
    },
)
async def list_notes(
    query: str | None = Query(default=None, description="Search query to filter notes"),
    tags: str | None = Query(default=None, description="Comma-separated list of tags to filter by"),
) -> NotesListResponse:
    """
    Retrieve all notes, optionally filtered by search query or tags.

    - **query**: Optional text search across title and content
    - **tags**: Optional comma-separated list of tags to filter by
    """
    try:
        service = _get_notes_service()

        # If query or tags provided, use search
        if query or tags:
            result = service.search_notes(query or "", filter_option="All")
        else:
            result = service.get_all_notes()

        if not result.success:
            log.warning("Failed to list notes: %s", result.error)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result.error,
            )

        notes_data = result.data
        if not isinstance(notes_data, list):
            notes_data = []

        # Convert to response format
        notes_response = [_convert_note_to_response(note) for note in notes_data]

        return NotesListResponse(
            notes=notes_response,
            total=len(notes_response),
        )

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error listing notes")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list notes: {str(e)}",
        ) from e


@router.get(
    "/{note_id}",
    response_model=NoteResponse,
    summary="Get a specific note",
    responses={
        200: {"description": "Note retrieved successfully"},
        404: {"description": "Note not found"},
        500: {"description": "Internal server error"},
    },
)
async def get_note(note_id: str) -> NoteResponse:
    """
    Retrieve a specific note by its ID.

    Returns the note with all its metadata including tags and timestamps.
    """
    try:
        service = _get_notes_service()
        result = service.get_note(note_id)

        if not result.success:
            log.warning("Note not found: %s", note_id)
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found",
            )

        note = result.data
        if not isinstance(note, Note):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invalid note data",
            )

        return _convert_note_to_response(note)

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error retrieving note %s", note_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve note: {str(e)}",
        ) from e


@router.put(
    "/{note_id}",
    response_model=NoteUpdatedResponse,
    summary="Update a note",
    responses={
        200: {"description": "Note updated successfully"},
        400: {"description": "Invalid request data"},
        404: {"description": "Note not found"},
        500: {"description": "Internal server error"},
    },
)
async def update_note(note_id: str, request: NoteUpdateRequest) -> NoteUpdatedResponse:
    """
    Update an existing note's fields.

    Only provided fields will be updated. Omitted fields remain unchanged.
    """
    try:
        service = _get_notes_service()

        # Build updates dict from non-None fields
        updates: dict[str, Any] = {}
        if request.title is not None:
            updates["title"] = request.title
        if request.content is not None:
            updates["content"] = request.content
        if request.tags is not None:
            updates["tags"] = request.tags
        if request.project_id is not None:
            updates["project_id"] = request.project_id

        if not updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update",
            )

        result = service.update_note(note_id, updates)

        if not result.success:
            # Determine if it's a not found or validation error
            if "not found" in result.error.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=result.error,
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=result.error,
            )

        return NoteUpdatedResponse(
            message="Note updated successfully",
            updated_fields=list(updates.keys()),
            warnings=result.warnings or [],
        )

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error updating note %s", note_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update note: {str(e)}",
        ) from e


@router.delete(
    "/{note_id}",
    response_model=NoteDeletedResponse,
    summary="Delete a note",
    responses={
        200: {"description": "Note deleted successfully"},
        404: {"description": "Note not found"},
        500: {"description": "Internal server error"},
    },
)
async def delete_note(
    note_id: str,
    hard: bool = Query(
        default=False, description="Permanently delete (true) or soft delete (false)"
    ),
) -> NoteDeletedResponse:
    """
    Delete a note by its ID.

    - **hard=false**: Soft delete (default) - note can be restored later
    - **hard=true**: Permanent deletion - note cannot be recovered
    """
    try:
        service = _get_notes_service()
        result = service.delete_note(note_id, hard_delete=hard)

        if not result.success:
            if "not found" in result.error.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=result.error,
                )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result.error,
            )

        if isinstance(result.data, dict):
            message = result.data.get("message", "Note deleted successfully")
        else:
            message = "Note deleted successfully"
        return NoteDeletedResponse(message=message)
    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error deleting note %s", note_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete note: {str(e)}",
        ) from e
