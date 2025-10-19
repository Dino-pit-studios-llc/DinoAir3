"""
Projects API routes for DinoAir.

Provides RESTful endpoints for managing projects with hierarchical support.
"""

from __future__ import annotations

import logging
from typing import Any

from database.initialize_db import DatabaseManager
from database.projects_db import ProjectsDatabase
from fastapi import APIRouter, HTTPException, Query, status
from models.project import Project, ProjectStatus
from pydantic import BaseModel, Field, field_validator

log = logging.getLogger("api.routes.projects")

router = APIRouter(prefix="/api/v1/projects", tags=["projects"])

_db_manager = DatabaseManager()
_projects_db = ProjectsDatabase(_db_manager)

PROJECT_NOT_FOUND_MESSAGE = "Project not found"

# -----------------------
# Request/Response Models
# -----------------------


class ProjectCreateRequest(BaseModel):
    """Request model for creating a new project."""

    name: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="", max_length=5000)
    status: str = Field(default="active")
    color: str | None = Field(default=None, max_length=20)
    icon: str | None = Field(default=None, max_length=50)
    parent_project_id: str | None = Field(default=None, max_length=100)
    tags: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] | None = Field(default=None)

    @field_validator("name", "description")
    @classmethod
    def _trim_strings(cls, v: str) -> str:
        """Trim whitespace from string fields."""
        return v.strip()

    @field_validator("status")
    @classmethod
    def _validate_status(cls, v: str) -> str:
        """Validate project status."""
        valid_statuses = ["active", "completed", "archived"]
        if v.lower() not in valid_statuses:
            raise ValueError(f"Status must be one of: {', '.join(valid_statuses)}")
        return v.lower()

    @field_validator("tags")
    @classmethod
    def _validate_tags(cls, v: list[str]) -> list[str]:
        """Validate and clean tags."""
        if not v:
            return []
        cleaned = [tag.strip() for tag in v if tag and tag.strip()]
        if len(cleaned) > 20:
            raise ValueError("Maximum 20 tags allowed")
        for tag in cleaned:
            if len(tag) > 50:
                raise ValueError("Individual tags must be 50 characters or less")
        return cleaned


class ProjectUpdateRequest(BaseModel):
    """Request model for updating an existing project."""

    name: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=5000)
    status: str | None = Field(default=None)
    color: str | None = Field(default=None, max_length=20)
    icon: str | None = Field(default=None, max_length=50)
    parent_project_id: str | None = Field(default=None, max_length=100)
    tags: list[str] | None = Field(default=None)
    metadata: dict[str, Any] | None = Field(default=None)

    @field_validator("name", "description")
    @classmethod
    def _trim_strings(cls, v: str | None) -> str | None:
        """Trim whitespace from string fields."""
        return v.strip() if v else None

    @field_validator("status")
    @classmethod
    def _validate_status(cls, v: str | None) -> str | None:
        """Validate project status."""
        if v is None:
            return None
        valid_statuses = ["active", "completed", "archived"]
        if v.lower() not in valid_statuses:
            raise ValueError(f"Status must be one of: {', '.join(valid_statuses)}")
        return v.lower()

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


class ProjectResponse(BaseModel):
    """Response model for a single project."""

    id: str
    name: str
    description: str
    status: str
    color: str | None
    icon: str | None
    parent_project_id: str | None
    tags: list[str]
    metadata: dict[str, Any] | None
    created_at: str | None
    updated_at: str | None
    completed_at: str | None
    archived_at: str | None

    @classmethod
    def from_project(cls, project: Project) -> ProjectResponse:
        """Convert a Project model to response format."""
        return cls(
            id=project.id,
            name=project.name,
            description=project.description,
            status=(project.status.value if isinstance(project.status, ProjectStatus) else project.status),
            color=project.color,
            icon=project.icon,
            parent_project_id=project.parent_project_id,
            tags=project.tags if isinstance(project.tags, list) else [],
            metadata=project.metadata,
            created_at=project.created_at,
            updated_at=project.updated_at,
            completed_at=project.completed_at,
            archived_at=project.archived_at,
        )


class ProjectsListResponse(BaseModel):
    """Response model for a list of projects."""

    projects: list[ProjectResponse]
    total: int


class ProjectCreatedResponse(BaseModel):
    """Response model for successful project creation."""

    id: str
    message: str


class ProjectUpdatedResponse(BaseModel):
    """Response model for successful project update."""

    message: str
    updated_fields: list[str] = Field(default_factory=list)


class ProjectDeletedResponse(BaseModel):
    """Response model for successful project deletion."""

    message: str


# -----------------------
# Helper Functions
# -----------------------


def _get_projects_db() -> ProjectsDatabase:
    """Get an instance of the projects database."""
    return _projects_db


def _convert_project_to_response(project: Project) -> ProjectResponse:
    """Convert a Project model to API response format."""
    return ProjectResponse.from_project(project)


# -----------------------
# Route Handlers
# -----------------------


@router.post(
    "",
    response_model=ProjectCreatedResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new project",
    responses={
        201: {"description": "Project created successfully"},
        400: {"description": "Invalid request data"},
        500: {"description": "Internal server error"},
    },
)
async def create_project(request: ProjectCreateRequest) -> ProjectCreatedResponse:
    """
    Create a new project with the provided details.

    The project will be assigned a unique ID and timestamp automatically.
    Supports hierarchical organization via parent_project_id.
    """
    try:
        projects_db = _get_projects_db()

        # Create Project model instance
        project = Project(
            id="",  # Will be generated
            name=request.name,
            description=request.description,
            status=ProjectStatus(request.status),
            color=request.color,
            icon=request.icon,
            parent_project_id=request.parent_project_id,
            tags=request.tags,
            metadata=request.metadata,
        )

        # Create project in database
        result = projects_db.create_project(project)

        if not result.get("success"):
            error_msg = result.get("error", "Failed to create project")
            log.warning("Failed to create project: %s", error_msg)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_msg,
            )

        return ProjectCreatedResponse(
            id=project.id,
            message="Project created successfully",
        )

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error creating project")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create project: {str(e)}",
        ) from e


@router.get(
    "",
    response_model=ProjectsListResponse,
    summary="List all projects",
    responses={
        200: {"description": "List of projects retrieved successfully"},
        500: {"description": "Internal server error"},
    },
)
async def list_projects(
    status_filter: str | None = Query(default=None, description="Filter by status (active, completed, archived)"),
    parent_id: str | None = Query(default=None, description="Filter by parent project ID"),
) -> ProjectsListResponse:
    """
    Retrieve all projects, optionally filtered by status or parent project.

    - **status_filter**: Optional filter by project status
    - **parent_id**: Optional filter to get children of a specific project
    - **include_children**: Whether to include hierarchical children
    """
    try:
        projects_db = _get_projects_db()

        # Get all projects
        projects = projects_db.get_all_projects()

        # Apply filters
        if status_filter:
            status_filter_lower = status_filter.lower()
            projects = [
                p
                for p in projects
                if (p.status.value if isinstance(p.status, ProjectStatus) else p.status) == status_filter_lower
            ]

        if parent_id is not None:
            # Filter by parent_id (use empty string to get root projects)
            projects = [p for p in projects if p.parent_project_id == (parent_id if parent_id else None)]

        # Convert to response format
        projects_response = [_convert_project_to_response(p) for p in projects]

        return ProjectsListResponse(
            projects=projects_response,
            total=len(projects_response),
        )

    except Exception as e:
        log.exception("Unexpected error listing projects")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list projects: {str(e)}",
        ) from e


@router.get(
    "/{project_id}",
    response_model=ProjectResponse,
    summary="Get a specific project",
    responses={
        200: {"description": "Project retrieved successfully"},
        404: {"description": PROJECT_NOT_FOUND_MESSAGE},
        500: {"description": "Internal server error"},
    },
)
async def get_project(project_id: str) -> ProjectResponse:
    """
    Retrieve a specific project by its ID.

    Returns the project with all its metadata including tags and timestamps.
    """
    try:
        projects_db = _get_projects_db()
        project = projects_db.get_project_by_id(project_id)

        if not project:
            log.warning("%s: %s", PROJECT_NOT_FOUND_MESSAGE, project_id)
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=PROJECT_NOT_FOUND_MESSAGE,
            )

        return _convert_project_to_response(project)

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error retrieving project %s", project_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve project: {str(e)}",
        ) from e


@router.put(
    "/{project_id}",
    response_model=ProjectUpdatedResponse,
    summary="Update a project",
    responses={
        200: {"description": "Project updated successfully"},
        400: {"description": "Invalid request data"},
        404: {"description": PROJECT_NOT_FOUND_MESSAGE},
        500: {"description": "Internal server error"},
    },
)
async def update_project(project_id: str, request: ProjectUpdateRequest) -> ProjectUpdatedResponse:
    """
    Update an existing project's fields.

    Only provided fields will be updated. Omitted fields remain unchanged.
    """
    try:
        projects_db = _get_projects_db()

        # Check if project exists
        existing_project = projects_db.get_project_by_id(project_id)
        if not existing_project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=PROJECT_NOT_FOUND_MESSAGE,
            )

        # Build updates dict from non-None fields
        updates: dict[str, Any] = {}
        if request.name is not None:
            updates["name"] = request.name
        if request.description is not None:
            updates["description"] = request.description
        if request.status is not None:
            updates["status"] = request.status
        if request.color is not None:
            updates["color"] = request.color
        if request.icon is not None:
            updates["icon"] = request.icon
        if request.parent_project_id is not None:
            updates["parent_project_id"] = request.parent_project_id
        if request.tags is not None:
            updates["tags"] = request.tags
        if request.metadata is not None:
            updates["metadata"] = request.metadata

        if not updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update",
            )

        # Update in database
        success = projects_db.update_project(project_id, updates)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to update project",
            )

        return ProjectUpdatedResponse(
            message="Project updated successfully",
            updated_fields=list(updates.keys()),
        )

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error updating project %s", project_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update project: {str(e)}",
        ) from e


@router.delete(
    "/{project_id}",
    response_model=ProjectDeletedResponse,
    summary="Delete a project",
    responses={
        200: {"description": "Project deleted successfully"},
        404: {"description": PROJECT_NOT_FOUND_MESSAGE},
        500: {"description": "Internal server error"},
    },
)
async def delete_project(project_id: str) -> ProjectDeletedResponse:
    """
    Delete a project by its ID.

    This will permanently delete the project and may affect child projects
    depending on database configuration.
    """
    try:
        projects_db = _get_projects_db()

        # Check if project exists
        existing_project = projects_db.get_project_by_id(project_id)
        if not existing_project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=PROJECT_NOT_FOUND_MESSAGE,
            )

        # Delete project
        success = projects_db.delete_project(project_id)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete project",
            )

        return ProjectDeletedResponse(message="Project deleted successfully")

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error deleting project %s", project_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete project: {str(e)}",
        ) from e


@router.get(
    "/{project_id}/children",
    response_model=ProjectsListResponse,
    summary="Get child projects",
    responses={
        200: {"description": "Child projects retrieved successfully"},
        404: {"description": PROJECT_NOT_FOUND_MESSAGE},
        500: {"description": "Internal server error"},
    },
)
async def get_child_projects(project_id: str) -> ProjectsListResponse:
    """
    Get all direct child projects of a specific project.

    Useful for building hierarchical project trees.
    """
    try:
        projects_db = _get_projects_db()

        # Verify parent exists
        parent_project = projects_db.get_project_by_id(project_id)
        if not parent_project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parent project not found",
            )

        # Get child projects
        child_projects = projects_db.get_child_projects(project_id)

        # Convert to response format
        projects_response = [_convert_project_to_response(p) for p in child_projects]

        return ProjectsListResponse(
            projects=projects_response,
            total=len(projects_response),
        )

    except HTTPException:
        raise
    except Exception as e:
        log.exception("Unexpected error retrieving child projects for %s", project_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve child projects: {str(e)}",
        ) from e
