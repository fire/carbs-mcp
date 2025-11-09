# ADR-012: Testing CARBS with Distribution Playground

**Status:** Accepted **Date:** 2025-01-09 **Context:** Need to validate CARBS
optimizer functionality with realistic test cases. Standard unit tests verify
code correctness, but integration tests with actual optimization problems
provide confidence in real-world performance.

**Decision:** Use distribution playground datasets (e.g.,
[distribution_playground](https://github.com/DIYer22/distribution_playground))
as test cases for CARBS optimizer validation.

**Consequences:**

- **Pros:**
  - Real-world optimization scenarios (2D probability distributions)
  - Various complexity levels (simple to complex distributions)
  - Well-defined ground truth for validation
  - Visual validation capabilities
  - Reproducible test cases
  - Tests hyperparameter optimization in realistic settings
  - Can measure divergence metrics between optimized and target distributions
- **Cons:**
  - Additional dependency for testing
  - Longer test execution time
  - Requires Python environment with distribution_playground installed
  - May need custom test fixtures

**Implementation:**

- Add distribution_playground to test dependencies (via Pythonx uv project in
  test config)
- Create integration tests that:
  - Sample from distribution playground density maps
  - Use CARBS to optimize hyperparameters for generative models
  - Measure divergence between optimized and target distributions
  - Validate convergence metrics
- Use various distribution types (simple to complex) to test different
  optimization scenarios
- Generate visualization outputs for manual inspection

**Test Scenarios:**

1. **Simple distributions**: Verify basic optimization works
2. **Complex distributions**: Test optimizer on challenging landscapes
3. **Custom density maps**: Test with arbitrary probability distributions
4. **Convergence validation**: Ensure optimizer improves over iterations
5. **Divergence metrics**: Measure KL divergence, Wasserstein distance, etc.

**Alternatives Considered:**

- Synthetic test functions only: Rejected - not representative of real use cases
- No integration tests: Rejected - need confidence in real-world performance
- Other test datasets: Considered but distribution_playground provides good
  variety and visualization

**References:**

- [distribution_playground repository](https://github.com/DIYer22/distribution_playground)
- Provides 2D probability distributions for generative model testing
- Includes divergence metric calculations
- Supports custom probability density maps

**Note:** These tests should be marked as integration tests and may be skipped
in CI if distribution_playground is not available. They provide valuable
validation but are not required for basic functionality verification.
