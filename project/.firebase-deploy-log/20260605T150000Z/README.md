# Deploy snapshot — 20260605T150000Z

Feature: couple-code

- Target: firestore:rules
- Projects: dev (tonyembeiu-dev) + prod (tonyembeiu)
- Exit: 0 (both)
- Changes: Added couple_codes collection rules; updated isValidCoupleDocument/isStrictCoupleDocument/onlyAllowedCoupleFieldsChanged to allow optional coupleCode field on couples
- Git branch: phase2
