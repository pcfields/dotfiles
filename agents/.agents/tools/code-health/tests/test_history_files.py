from code_health.history import machine_name


def test_machine_name_is_a_safe_file_name_part():
    assert machine_name("Peter's Laptop.local") == "peter-s-laptop.local"
    assert machine_name("DESKTOP-ABC123") == "desktop-abc123"
    assert machine_name("") == "unknown"
