"""
Test utilities.responses module

Quick validation that response utilities work correctly.
"""

from utils.responses import data_response, error_response, success_response


def test_success_response():
    """Test success response formatting."""
    # Basic success
    result = success_response()
    assert result == {"success": True}

    # With data
    result = success_response(data={"id": "123"})
    assert result == {"success": True, "data": {"id": "123"}}

    # With message
    result = success_response(message="Operation completed")
    assert result == {"success": True, "message": "Operation completed"}

    print("✅ success_response tests passed")


def test_error_response():
    """Test error response formatting."""
    # Basic error with exception
    result = error_response(ValueError("Bad input"))
    assert result["success"] is False
    assert result["error"] == "Bad input"

    # With context
    result = error_response("Not found", context="User lookup")
    assert result == {"success": False, "error": "Not found", "context": "User lookup"}

    # With type
    result = error_response(ValueError("Bad"), include_type=True)
    assert result["error_type"] == "ValueError"

    print("✅ error_response tests passed")


def test_data_response():
    """Test flexible data response."""
    # Success with data
    result = data_response(True, data={"count": 5})
    assert result["success"] is True
    assert result["data"] == {"count": 5}

    # Failure with error
    result = data_response(False, error="Failed")
    assert result["success"] is False
    assert result["error"] == "Failed"

    print("✅ data_response tests passed")


if __name__ == "__main__":
    test_success_response()
    test_error_response()
    test_data_response()
    print("\n✅ All response utility tests passed!")
