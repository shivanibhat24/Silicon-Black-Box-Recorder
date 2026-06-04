#!/usr/bin/env python3
# =============================================================================
# Silicon Black Box Recorder — Regression Runner
# run_regression.py
#
# Discovers and runs all Cocotb tests, collects results.
# Usage: python scripts/run_regression.py
# =============================================================================

import subprocess
import sys
import os
import glob
import time

VERIFICATION_DIR = os.path.join(os.path.dirname(__file__), '..', 'verification')
TESTS_DIR = os.path.join(VERIFICATION_DIR, 'tests')
RESULTS_DIR = os.path.join(os.path.dirname(__file__), '..', 'results')


def discover_tests():
    """Find all test_*.py files in the verification/tests directory."""
    pattern = os.path.join(TESTS_DIR, 'test_*.py')
    return sorted(glob.glob(pattern))


def run_test(test_file):
    """Run a single Cocotb test and return the result."""
    test_name = os.path.basename(test_file).replace('.py', '')
    print(f"\n{'='*60}")
    print(f"  Running: {test_name}")
    print(f"{'='*60}")

    start = time.time()
    result = subprocess.run(
        ['make', '-C', os.path.join(VERIFICATION_DIR, 'tb'),
         f'MODULE={test_name}'],
        capture_output=True,
        text=True
    )
    elapsed = time.time() - start

    passed = result.returncode == 0
    status = "PASS" if passed else "FAIL"
    print(f"  [{status}] {test_name} ({elapsed:.1f}s)")

    return {
        'name': test_name,
        'status': status,
        'elapsed': elapsed,
        'stdout': result.stdout,
        'stderr': result.stderr,
    }


def main():
    os.makedirs(RESULTS_DIR, exist_ok=True)

    tests = discover_tests()
    if not tests:
        print("No test files found!")
        sys.exit(1)

    print(f"Discovered {len(tests)} test(s)")

    results = []
    for t in tests:
        results.append(run_test(t))

    # Summary
    print(f"\n{'='*60}")
    print("  REGRESSION SUMMARY")
    print(f"{'='*60}")
    passed = sum(1 for r in results if r['status'] == 'PASS')
    failed = sum(1 for r in results if r['status'] == 'FAIL')
    for r in results:
        print(f"  [{r['status']}] {r['name']} ({r['elapsed']:.1f}s)")
    print(f"\n  Total: {len(results)}  Passed: {passed}  Failed: {failed}")

    # Write results file
    results_file = os.path.join(RESULTS_DIR, 'regression_results.txt')
    with open(results_file, 'w') as f:
        for r in results:
            f.write(f"[{r['status']}] {r['name']} ({r['elapsed']:.1f}s)\n")
        f.write(f"\nTotal: {len(results)}  Passed: {passed}  Failed: {failed}\n")
    print(f"\n  Results written to: {results_file}")

    sys.exit(0 if failed == 0 else 1)


if __name__ == '__main__':
    main()
