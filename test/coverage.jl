using Coverage

coverage_src = process_folder("../src")
coverage_test = process_folder("../test")
coverage = merge_coverage_counts(coverage_src, coverage_test)
LCOV.writefile("htmlcov/coverage.info", coverage)
