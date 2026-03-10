#!/bin/bash
# Test suite for Zero Trust Policy Script

set -e

SCRIPT="$(dirname "$0")/zero-trust-policy.sh"

# Test 1: Intake
(echo 1; echo "TestUser"; echo "IT") | bash "$SCRIPT"

# Test 2: Admin Search (should succeed)
(echo 2; echo "adminpass") | bash "$SCRIPT"

# Test 3: Audit Log
(echo 3) | bash "$SCRIPT"

# Test 4: Archive & Sign
(echo 4) | bash "$SCRIPT"

# Test 5: Exit
(echo 5) | bash "$SCRIPT"

echo "All tests completed."
