# DNA v2 Design (Continuous, Normalized, and Extensible)

Goal: Redesign the DNA system so small changes in DNA cause small, continuous changes in the car wherever feasible. Use longer DNA strings to encode richer parameters. Draw all tunable parameters from normal distributions, with the DNA modulating the mean and/or deviation in a smooth way.

## Principles

- Continuity first: Neighboring DNA strings map to neighboring cars (minimize discontinuities).
- Length-agnostic: DNA can be any length. More characters increase resolution/entropy, but there is no fixed minimum or target length.
- Normal distributions: Parameters are sampled from N(μ, σ²) using deterministic PRNG seeded by DNA; DNA bits continuously modulate μ and σ.
- Deterministic: Same DNA produces identical car build and behavior.
- Neutral priors: No built-in bias toward specific shapes; evolution provides pressure.
- Bounded & stable: Clamp outputs to safe ranges and smooth near bounds.

## High-level Encoding

- DNA: base62 string (0-9A-Za-z) of arbitrary length. Non-alphanumeric filtered out during validation.
- Stream decoder: Convert base62 chars → integer stream → [0,1) floats via hash/PRNG; advance as values are consumed.
- Parameter channels: Reserve contiguous slices of the stream for different subsystems. Each channel has a spec with:
  - base_mean, base_std (global defaults)
  - mean_mod, std_mod functions mapping [0,1) → deltas (smooth via splines or polynomials)
  - clamps and soft-limits

## Data Model

- Car length (module count): Smoothly determined by an accumulator threshold.
  - We scan a length channel producing u in [0,1); accumulate until sum > T (e.g., 3.5) → number of modules M = floor(sum) + 2. Small changes in u shift M only near boundaries.
- Module sequence (frame): Use a continuous categorical with temperature.
  - For each module i, compute logits for {Rectangle, Wheel, Connector, Void} from u’s; temperature τ ∈ [0.2, 1.5] set by DNA; argmax → discrete part. Continuity preserved except at rare decision boundaries.
- Powertrain sequence: Similar softmax categorization into {Cylinder, DriveShaft, GearSet, Motor, Diff}. Separate channel and temperature.

- Connectors (between rectangles): When two rectangles are adjacent in the module sequence, generate a rotational connector with continuous target angle and flex so rectangles can connect at angles in [-90°, +90°].

## Parameterization (examples; all DNA-modulated via μ/σ)

- Rectangle:
  - width ~ N(μ=48, σ=10) → clamp [24, 120]
  - height ~ N(μ=24, σ=6) → clamp [12, 60]
  - density ~ N(μ=1.0, σ=0.25) → mass from area*density
  - local_offset_x/y ~ N(μ=0, σ=4) to jitter connections slightly but continuously
- Wheel:
  - radius ~ N(μ=18, σ=6) clamp [10, 40]
  - tire_friction ~ N(μ=1.0, σ=0.3) clamp [0.4, 2.0]
  - motor_power ~ N(μ=90, σ=40) clamp [0, 200]
  - motor_bias per axle from N(μ=0.5, σ=0.15) ∈ [0,1]
- Powertrain:
  - gear_ratio_i ~ N(μ=2.0, σ=0.6) per stage
  - efficiency ~ N(μ=0.9, σ=0.05)
  - throttle_map curvature ~ N(μ=1.0, σ=0.3)
- Global:
  - center_of_mass shift ~ N(μ=0, σ=5)
  - damping linear/angular ~ N(μ=[0.1,0.2], σ=[0.05,0.05])
  - suspension stiffness/damping if added later

- Connector (rectangle-to-rectangle rotational flex):
  - angle_deg ~ N(μ=0, σ=20) clamp [-90, 90]
  - stiffness_k ~ N(μ=0.8, σ=0.3) clamp [0.1, 2.0]
  - damping_c ~ N(μ=0.4, σ=0.2) clamp [0.05, 1.0]
  - slack_deg ~ N(μ=2, σ=1) clamp [0, 10]

## Continuous Mapping Mechanics

- u ∈ [0,1) from PRNG → z = Φ⁻¹(u) (inverse CDF of standard normal) to get a standard normal variate.
- μ(u_m) = base_mean + mean_mod(u_m); σ(u_s) = base_std * exp(std_mod(u_s)) to keep σ > 0 and continuous.
- Final param p = clamp(μ + σ * z, min, max). All functions smooth (e.g., cubic Hermite or simple polynomials).
- Discrete choices (module types) use softmax over logits derived from continuous functions; discontinuities only at decision boundaries.

## Layout & Connectivity

- Chassis spine x positions advance by smooth increments Δx_i ~ N(μ=50, σ=10) with cumulative sum → anchor_x[i]. Small DNA changes shift anchors smoothly; module switch boundaries are the only jumps.
- Wheels snap to nearest existing anchor with a smooth tie-breaker (e.g., bias left/right by small continuous term).
- Connection jitter uses small continuous offsets that won’t break joints.

- Rectangle rotational connectors: For consecutive rectangles at anchors i and i+1, compute a target relative angle `theta_star` from the connector params. Apply a soft angular spring-damper torque each physics tick: `tau = k * (theta_star - theta) - c * omega_rel`, capped for stability. This yields flexible joints that can act like emergent suspension without explicitly encoding suspension parts.

## Deterministic PRNG

- Seed = 64-bit hash of DNA string (e.g., xxHash64 or Godot’s HashingContext + FNV fallback).
- PRNG = SplitMix64 → convert to floats in (0,1). Stateless mapping allows indexed access for stability across insertions if needed.
- Optional: Address stability under insert/delete by using positional hashing (char_index + stream_index) to localize effects.

## Versioning

- v2 is the new format and the only supported path going forward. Legacy prototype formats are not supported.

## Godot Integration Points

- CarDNA.gd:
  - New methods: set_version(v2), translate_v2(), get_param(channel, idx), prng_at(index), inv_cdf_normal(u).
  - Validation: explicit base62; length >= 24 (prefer >= 48).
- Car.gd:
  - Update build_in to use v2 when present; read module list, anchors, and parameters per module.
  - Wheel power/size come from v2 parameter channels.
- CarSimulation.gd: unchanged orchestrator; physics stability via bounds.

## Testing Strategy

- Property-based tests in old_code reference (Python) and mirrored in GDScript where feasible.
- Continuity tests: small one-char edits → small deltas in measured parameters (L2 distance over sampled params).
- Determinism tests: same DNA → same params; ordering stability under non-overlapping edits.
- Bounds tests: no NaNs; clamps respected; physics-safe ranges.

## Migration Plan

1) Implement PRNG + base62 decoder + inv-normal in CarDNA.gd.
2) Define channels and parameter specs; wire μ/σ modulation functions.
3) Implement frame/powertrain translators using softmax with temperature.
4) Update Car.build_in to consume v2 outputs.
5) Keep v1 codepaths; add config toggle and logging.
6) Add tests + visual debug overlays for anchors and module boxes.

## Open Questions

- Exact default DNA length? Propose 96 for redundancy; configurable via PopulationManager.
- Temperature scheduling from DNA versus global tuning?
- Do we want explicit axles (front/rear) as first-class concepts for smoother power assignment?
- How to ensure stability under length-changing mutations (insert/delete)? Prefer localized hashing to keep effects local.
- Persistence/serialization versioning scheme for saved populations.

---

## Addendum A: Concrete Channel Map (initial)

- Header (2 chars): version/options (e.g., temperature scaling mode, v2 flag).
- Length channel (~10%): determines module count M and Δx_i increments.
- Module type channel (~20%): logits for frame modules per position.
- Powertrain type channel (~15%): logits per position.
- Rectangle params (~20%): width, height, density, jitter x/y per module.
- Wheel params (~20%): radius, friction, motor_power, axle bias per wheel.
- Global params (~15%): damping, CoM shift, temperature τ, friction bias.

Note: Channels are virtual. We derive them via indexed hashing rather than literal contiguous slices to preserve locality under insert/delete.

## Addendum B: Locality-Preserving PRNG

- Global seed: 64-bit hash of full DNA for globals/ties only.
- Counter/local hashing: For channel C and index i, use a small window w around i:
  - H(C,i) = XOR over j ∈ [i-w, i+w] of mix64(C, i, j, base62_value(dna[j]))
  - mix64: SplitMix64-style avalanche of a composed 64-bit key.
- Uniform conversion: u = ((H >> 11) & ((1<<53)-1)) / 2^53 ∈ [0,1).
- Locality: Only indices within ±w are affected by a single-char mutation.

Locality window explained:

- The window size `w` defines how far a single-character edit can influence generated parameters. With `w = 4`, changing DNA at index `k` influences only indices `k-4..k+4` across channels; indices outside that range remain unchanged. This gives smooth, local effects from small mutations and keeps distant parts of the car stable as DNA grows.

## Addendum C: Mapping Formulas

- mean_mod(u) = a0 + a1*(2u-1) + a2*smoothstep(0,1,u)
- `std_mod(u) = b0 + b1*(2u-1)`; `sigma = sigma0 * exp(std_mod(u))` with `sigma` clamped to `[sigma_min, sigma_max]`
- Softmax logits: l_k = α_k + β_k*(2u_k-1); temperature τ from globals; pick argmax(l/τ)

## Addendum D: Implementation Sketch (pseudo-GDScript)

```gdscript
func base62_val(ch: String) -> int:
  # returns 0..61; treat others as 0

func mix64(c: int, i: int, j: int, v: int) -> int:
  var x: int = (uint64(c) << 56) ^ (uint64(i) << 40) ^ (uint64(j) << 24) ^ uint64(v)
  x ^= x >> 30; x *= 0xbf58476d1ce4e5b9
  x ^= x >> 27; x *= 0x94d049bb133111eb
  x ^= x >> 31
  return x

func u(channel: int, idx: int, w: int = 4) -> float:
  var h: int = 0
  var n := dna_string.length()
  for j in range(max(0, idx-w), min(n, idx+w+1)):
    h ^= mix64(channel, idx, j, base62_val(dna_string[j]))
  var mantissa: int = (h >> 11) & ((1 << 53) - 1)
  return float(mantissa) / float(1 << 53)

func z_normal(channel: int, idx: int) -> float:
  var uu := clamp(u(channel, idx), 1e-9, 1.0 - 1e-9)
  return inv_cdf_standard_normal(uu)
```

API surfaces to add in `scripts/CarDNA.gd`:

- set_version(v: int), is_v2(): bool
- translate_v2(): Dictionary { modules, anchors, params }
- u(channel: int, idx: int): float; z_normal(channel: int, idx: int): float
- module_type_logits(i): PackedFloat32Array
- rect_params(i): Dictionary; wheel_params(i): Dictionary; powertrain_params(i): Dictionary; globals(): Dictionary

## Addendum E: Testing and Migration Notes

- Continuity: One-char Hamming distance at k affects only indices i with |i-k| ≤ w; assert bounded param diff.
- Determinism: Same DNA → same outputs (within float epsilon) across runs.
- Safety: No NaNs; all clamped to safe physics ranges.

Incremental rollout:

1) Implement globals + wheel radius/power via v2; keep v1 for module types initially.
2) Switch frame sequence to v2 logits + Δx anchors.
3) Move powertrain to v2 and enable full v2 toggle.

## Addendum F: Clarifying Questions

- Target default DNA length 96 OK? Any upper bound for performance?
- Preferred locality window size w (suggest 4)?
- Initial module vocabulary: {Rectangle, Wheel, Connector} sufficient?
- Bias toward 4-wheel configs early on, or fully neutral priors?
