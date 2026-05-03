# Gray-Code Pointers

**Category**: CDC · **Used in**: W7 (async FIFO RTL), W19 · **Type**: auto-stub

Gray code: an N-bit binary encoding where consecutive values differ
in exactly 1 bit. Used for multi-bit CDC where the *only* change per
cycle is +1 (i.e. counters).

## Conversion

```
gray = bin ^ (bin >> 1);

// Inverse:
bin[N-1] = gray[N-1];
for (i = N-2; i >= 0; i--) bin[i] = bin[i+1] ^ gray[i];
```

## Why it works for CDC

If a counter increments at most once per clock and the receiver
samples mid-transition, only one bit is in flight. The 2-FF
synchroniser samples either the old gray value or the new — there is
no "garbage intermediate" to capture.

## Limitations

- Only works for monotonic up-counters (or wraparound). Random multi-
  bit values cannot use gray-code crossing.
- The 2-bit / 1-bit increment guarantee depends on the source-side
  counter incrementing exactly once per source clock — verify in TB.

## Reading

- Cummings *Async FIFO Design*, SNUG-2002.

## Cross-links

- `[[async_fifo]]`
- `[[two_ff_synchronizer]]`
- `[[multibit_handshake_cdc]]` — what to use when gray code can't.
