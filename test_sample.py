import pytest

def test_example():
    assert 1 + 1 == 2

def test_string_concat():
    assert "Zero" + "Trust" == "ZeroTrust"

def test_list_length():
    data = [1, 2, 3]
    assert len(data) == 3

def test_dict_lookup():
    info = {"user": "admin", "role": "security"}
    assert info["role"] == "security"

def test_empty_list():
    data = []
    assert len(data) == 0

def test_key_error():
    info = {"user": "admin"}
    with pytest.raises(KeyError):
        _ = info["role"]

def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        _ = 1 / 0
