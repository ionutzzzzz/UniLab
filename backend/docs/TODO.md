# UniLab Development Roadmap

## 🐛 Current Issues (Priority 1)
- [ ] Fix Routh-Hurwitz table stability analysis - array truth value ambiguity in `routh_table.m`
  - Issue: `sign_changes` calculation returns array instead of scalar in Python transpilation
  - Location: `backend/libraries/control/routh_table.m:43`
  - Impact: Blocks `04_control_theory.m` sample execution

---

## 🎯 Phase 1: Core Stability & Quality (v0.2.0)

### Language & Transpiler Improvements
- [x] Fix array/scalar ambiguity in boolean contexts (numpy arrays in if/while conditions)
- [ ] Add string literal syntax support (currently only single quotes work)
- [ ] Implement proper cell array indexing with `{}` operator
- [ ] Add support for struct/record types
- [ ] Fix precision loss in floating-point operations
- [ ] Add support for multi-line comments `/* ... */`
- [ ] Improve error messages with line number tracking in source code
- [x] Implement basic type checking functions (`ischar`, `iscell`, `isnumeric`, `isequal`)

### Standard Library Expansion
- [ ] Complete missing math library functions (~20 needed for numeric analysis)
- [ ] Add comprehensive stats library (distributions, hypothesis tests, ANOVA)
- [ ] Implement remaining string processing functions (`strsplit`, `contains`, `replace`, etc.)
- [x] Added `strcmp`, `strcmpi`, `lower`, `upper`, `isequal`, `ischar`, `iscell`, `isnumeric`
- [ ] Implement signal processing package (filters, spectral analysis, wavelets)
- [ ] Add linear algebra utilities (QR, SVD refinements, pseudoinverse)
- [ ] Create optimization package (constrained solvers, quadratic programming)
- [ ] Add specialized packages: differential equations, PDE solvers, stochastic simulation

### Runtime & Performance
- [ ] Implement proper variable scoping (global/local/persistent)
- [ ] Add debugging/breakpoint support for REPL
- [ ] Optimize nested loop execution
- [ ] Add memory profiling for large matrix operations
- [ ] Implement garbage collection for workspace cleanup

---

## 🎨 Phase 2: Frontend & User Interface (v0.3.0)

### Web Interface (React/SCSS)
- [ ] Build interactive code editor with syntax highlighting
- [ ] Create workspace browser with variable inspection
- [ ] Add real-time plot rendering and visualization updates
- [ ] Implement multi-pane layout (code, output, plots, workspace)
- [ ] Add tabbed file management for .m scripts
- [ ] Create help sidebar with function documentation

### Visualization Engine
- [ ] Upgrade from ASCII plots to interactive matplotlib/plotly rendering
- [ ] Add 3D surface plotting (surf, mesh, contour)
- [ ] Implement heatmap with interactive colormap selection
- [ ] Add histogram and statistical plot types
- [ ] Create animated plot support (for parameter sweeps)
- [ ] Add export to SVG/PNG/PDF with quality options

### REPL Enhancement
- [ ] Add syntax highlighting in terminal
- [ ] Implement autocomplete with function signatures
- [ ] Add command history with persistent storage
- [ ] Create workspace variable browser in terminal
- [ ] Add macro/scripting support for common workflows

---

## 🚀 Phase 3: Advanced Features (v0.4.0)

### API Expansion
- [ ] Add batch execution endpoint for scripts
- [ ] Implement job queue system for long-running tasks
- [ ] Add WebSocket support for real-time output streaming
- [ ] Create collaborative editing with operational transformation
- [ ] Add REST endpoint for library discovery/search

### Machine Learning Integration
- [ ] Create ML pipeline builder (sklearn wrapper)
- [ ] Add neural network visualization (layer diagrams, activation maps)
- [ ] Implement cross-validation utilities
- [ ] Add hyperparameter tuning interface (grid search, Bayesian optimization)
- [ ] Create model evaluation metrics dashboard

### Scientific Computing
- [ ] Add symbolic math module (SymPy integration improvements)
- [ ] Implement partial differential equation solver
- [ ] Add Monte Carlo simulation framework
- [ ] Create optimization algorithm library (genetic, PSO, etc.)
- [ ] Add Fourier/Laplace transform utilities

### Data I/O
- [ ] CSV/Excel import with data preview
- [ ] HDF5/NetCDF support for scientific data
- [ ] JSON/YAML serialization for results
- [ ] Database connectivity (PostgreSQL, SQLite)
- [ ] Streaming data input from APIs/sensors

---

## 🔧 Phase 4: DevOps & Deployment (v0.5.0)

### Docker & Containerization
- [ ] Multi-stage Docker build for optimization
- [ ] Docker Compose with database and Redis cache
- [ ] Health checks and graceful shutdown
- [ ] Resource limits and monitoring

### Cloud Deployment
- [ ] Kubernetes YAML manifests
- [ ] Cloud function support (AWS Lambda, Google Cloud Functions)
- [ ] Containerized execution environments for isolation
- [ ] Multi-region deployment strategy

### Authentication & Security
- [ ] User authentication (JWT/OAuth2)
- [ ] Session management and timeout
- [ ] Role-based access control (RBAC)
- [ ] API key management
- [ ] Code sandbox/sandboxing for untrusted scripts

### Monitoring & Observability
- [ ] Structured logging with correlation IDs
- [ ] Prometheus metrics export
- [ ] APM integration (Datadog/New Relic)
- [ ] Error tracking and alerting
- [ ] Performance dashboards

---

## 📦 Phase 5: Ecosystem & Community (v1.0.0)

### Plugin System
- [ ] Plugin architecture for custom libraries
- [ ] Package manager (similar to pip/npm)
- [ ] Plugin marketplace/registry
- [ ] Documentation generation from plugins
- [ ] Version management and dependency resolution

### Community Features
- [ ] Notebook sharing platform
- [ ] Code snippet library with tagging
- [ ] User-contributed library distribution
- [ ] Forum/Q&A integration
- [ ] Tutorial and educational content system

### Documentation
- [ ] Comprehensive API documentation (Sphinx/ReadTheDocs)
- [ ] Interactive tutorials (Jupyter-style)
- [ ] Video tutorials for common workflows
- [ ] Scientific paper references and citations
- [ ] Migration guides from MATLAB/Octave

---

## 📊 Testing & Quality Metrics

### Current Status (2026-05-18)
- Test Coverage: 102/103 tests passing (99.0%)
- Core Language: Fully functional
- API: Fully operational with all endpoints
- Sample Scripts: 9/10 executing successfully
- Deprecation Warnings: 4 (SciPy namespace updates needed)

### Testing Roadmap
- [ ] Achieve 95%+ code coverage (currently ~85%)
- [ ] Add integration tests for all endpoints
- [ ] Create performance benchmarks
- [ ] Add load testing for concurrent sessions
- [ ] Implement regression test suite for samples
- [ ] Add fuzzing for parser robustness

---

## 🎓 Quick-Win Features (Can Do Anytime)

1. Add more mathematical constants (golden ratio, catalan constant, etc.)
2. Implement `pause()` function for interactive plotting
3. Add `input()` function for user input in scripts
4. Implement `warning()` and `error()` functions with proper behavior
5. Add date/time functions (`datetime`, `now`, etc.)
6. Create table/timetable data structure support
7. Add string manipulation functions (`strsplit`, `contains`, `replace`, etc.)
8. Implement proper `try-catch-finally` semantics
9. Add `parfor` (parallel for loop) support
10. Create debugging trace mode for troubleshooting

---

## 🏗️ Architectural Improvements

### Code Organization
- [ ] Split `runtime.py` into multiple modules (>1500 lines is too large)
- [ ] Create separate module for builtin functions
- [ ] Extract visualization logic into dedicated module
- [ ] Move API schemas to separate definitions file
- [ ] Create library management subsystem

### Refactoring
- [ ] Remove duplicate code in transpiler
- [ ] Create base class for all built-in functions
- [ ] Standardize error handling across modules
- [ ] Implement dependency injection for cleaner testing
- [ ] Add type hints throughout codebase

---

## 🔐 Security Hardening

- [ ] Code injection prevention in script execution
- [ ] Input validation for all API endpoints
- [ ] Rate limiting on API endpoints
- [ ] CSRF protection for web interface
- [ ] Content Security Policy headers
- [ ] Regular dependency security audits

---

## Performance Optimization

- [ ] Cache transpilation results
- [ ] Optimize matrix operations for large arrays
- [ ] Implement lazy evaluation where possible
- [ ] Add query result caching
- [ ] Reduce REPL startup time
- [ ] Profile and optimize hot paths

---

## Notes

- UniLab is positioned as a modern alternative to MATLAB/Octave
- Focus on accessibility: web-based or application, limited installation needed
- Key differentiator: modern UI + open-source + extensible
- Timeline: Realistic to reach v1.0 in 12-18 months
- Community contributions will be critical for library ecosystem

