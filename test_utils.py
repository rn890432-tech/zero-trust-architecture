import pytest

def test_max():
    assert max([1, 5, 3]) == 5

def test_min():
    assert min([-1, 0, 1]) == -1

def test_sorted():
    assert sorted([3, 1, 2]) == [1, 2, 3]
