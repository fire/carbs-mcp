# ADR-011: ETNF Normalization of Database Schema

**Status:** Accepted **Date:** 2025-01-09 **Context:** Initial database schema
stored CARBS optimizer state as a binary/blob field, which violates Entity Type
Normal Form (ETNF) principles. Need to normalize the schema to eliminate blob
storage and properly structure data.

**Decision:** Refactor database schema to follow ETNF principles by:

- Removing blob/text storage for serialized state
- Normalizing config fields into individual columns
- Creating separate tables for parameters, observations, and suggestions
- Reconstructing CARBS state from normalized data when needed

**Consequences:**

- **Pros:**
  - Proper database normalization (ETNF compliant)
  - Queryable data (can query observations, suggestions separately)
  - Better data integrity and referential constraints
  - Easier to analyze optimization history
  - No opaque blob storage
  - Better for backups and data migration
- **Cons:**
  - More complex schema (multiple tables)
  - State reconstruction overhead (rebuild from normalized data)
  - More database operations for state reconstruction
  - Slightly more complex code for saving/loading

**Implementation Details:**

1. **Normalized Tables:**
   - `carbs_optimizers`: Main table with normalized config fields (no blob)
   - `carbs_optimizer_params`: Parameter definitions (one row per parameter)
   - `carbs_observations`: Observation records (one row per observation)
   - `carbs_observation_params`: Parameter values for each observation
   - `carbs_suggestions`: Outstanding suggestions
   - `carbs_suggestion_params`: Parameter values for each suggestion

2. **State Reconstruction:**
   - When loading optimizer, reconstruct config and params from normalized
     tables
   - Create new CARBS instance with reconstructed config/params
   - Replay all observations to rebuild internal state
   - Serialized state is only used temporarily for Python operations

3. **Data Storage:**
   - Config fields stored as individual columns (integers, floats, booleans,
     strings)
   - Parameter space definitions normalized into columns
   - Observations stored with individual parameter values in separate table
   - No JSON/base64 blobs in database

**Alternatives Considered:**

- Keep blob storage: Rejected - violates ETNF, makes data unqueryable
- Hybrid approach (blob + normalized): Rejected - adds complexity, data
  duplication
- Store only essential data normalized: Considered but rejected - need full
  history for reconstruction

**Note:** The reconstruction overhead is acceptable because:

- CARBS operations are typically sequential and infrequent
- GP model fitting is the main bottleneck, not state reconstruction
- Normalized data provides significant benefits for querying and analysis
- State is only reconstructed when needed (lazy loading)
