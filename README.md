### What this function does

* **Character set:** All 94 printable ASCII characters (letters, digits, punctuation).
  In `LC_ALL=C`, that is exactly `[:alnum:]` + `[:punct:]`.
* **Diversity rule:** For `length ≥ 4`, passwords are accepted **only if** they contain at least one uppercase, one lowercase, one digit, and one punctuation character.
  For `length < 4`, this is mathematically impossible; the generator will still produce a uniformly random string from the 94‑character set.
* **Uniformity:** The function **samples uniformly** from all length‑`L` strings over the 94‑character set and **rejects** any sample that doesn’t satisfy the diversity rule. This yields a distribution that is **uniform over the valid set** (no bias from ad‑hoc shuffling).

### Installation & Usage

1. Copy the Zsh function into `~/.zshrc`.
2. Open a new terminal (so the function is loaded).
3. Run:

```bash
makepw          # one 20-character password
makepw 112      # one 112-character password
makepw -n 5     # five 20-character passwords
makepw -n 5 35  # five 35-character passwords
makepw --letters-only 24             # only A–Z a–z
makepw --no-digit 32                 # letters + punctuation (no digits)
makepw --alnum-only 24               # letters + digits (no punctuation)
makepw --no-diversity 16             # pure uniform from chosen set
makepw --avoid-ambiguous --alnum-only 20
makepw -n 5 --letters-only --clipboard
```

> **Note:** Some sites restrict which punctuation is allowed. This generator intentionally uses the full printable set. If a site rejects a password, re‑generate or temporarily reduce the character set for that site (you can modify the `tr` pattern to `'[:alnum:]'` or a custom subset).

### Security Model & Entropy (Corrected)

Let:

* `N = 94` (size of the printable ASCII set in `C` locale),
* `L` = password length.

If each of the `L` positions is an **independent uniform** draw from the 94‑character set, the unconstrained entropy is:

```
H_unconstrained(L) = L * log2(94)  ≈ L * 6.5546  bits
```

Because the function enforces “at least one of each class” (for `L ≥ 4`) by **rejection sampling**, the final distribution is **uniform over the subset** of strings that meet that rule. The true entropy is:

```
H(L) = log2( count_valid(L) )
```

where `count_valid(L)` is the number of length‑`L` strings over the 94‑set that contain ≥1 uppercase, ≥1 lowercase, ≥1 digit, and ≥1 punctuation. By inclusion–exclusion:

```
count_valid(L) =
  94^L
  − 68^L − 68^L − 84^L − 62^L
  + 42^L + 58^L + 36^L + 58^L + 36^L + 52^L
  − 32^L − 10^L − 26^L − 26^L
```

(26 uppercase, 26 lowercase, 10 digits, 32 punctuation.)

It’s convenient to express the **tiny penalty** versus the unconstrained maximum:

```
Penalty(L) = H_unconstrained(L) − H(L)  (bits)
```

and the **acceptance probability** of one draw (how often we have to re‑draw):

```
p_accept(L) = count_valid(L) / 94^L
```

For common lengths:

|      L | H\_unconstrained (bits) |  H(L) (bits) | Penalty (bits) |   p\_accept | Expected draws (1/p) |
| -----: | ----------------------: | -----------: | -------------: | ----------: | -------------------: |
|      4 |                 26.2184 |      22.3078 |         3.9106 |     0.06650 |                15.04 |
|      5 |                 32.7729 |      30.1843 |         2.5887 |     0.16624 |                 6.02 |
|      8 |                 52.4367 |      51.3183 |         1.1184 |     0.46060 |                 2.17 |
|     12 |                 78.6551 |      78.1401 |         0.5149 |     0.69983 |                 1.43 |
|     16 |                104.8734 |     104.5925 |         0.2809 |     0.82307 |                 1.21 |
| **20** |            **131.0918** | **130.9259** |     **0.1659** | **0.89137** |             **1.12** |
| **30** |            **196.6377** | **196.5872** |     **0.0504** | **0.96564** |             **1.04** |
|     64 |                419.4937 |     419.4926 |         0.0011 |     0.99925 |               1.0007 |
|    128 |                838.9874 |     838.9874 |      0.0000008 |   0.9999994 |            1.0000006 |
|    512 |               3355.9495 |    3355.9495 |            \~0 |       \~1.0 |                \~1.0 |

**Takeaways**

* For practical lengths (≥20), the “diversity” rule’s entropy penalty is **negligible** (≈0.17 bits at L=20; ≈0.05 bits at L=30).
* The generator’s **min‑entropy** equals `H(L)` because the distribution is uniform over valid outputs.
* The common heuristic “entropy = length × log2(unique characters used in *this one* password)” is **incorrect**. Entropy depends on the *generating process*, not how many distinct symbols happened to appear in a single sample.

### Notes & Tips

* **Copy/paste robustness:** The function prints with `print --`, so characters are not interpreted by the shell.
* **Site restrictions:** If a site disallows certain punctuation, either regenerate or temporarily switch the generator to a stricter set (edit the `tr` pattern to `'[:alnum:]'` or a curated list).
* **Very short passwords:** For `L < 4`, diversity checks are impossible; use a longer length for real security.