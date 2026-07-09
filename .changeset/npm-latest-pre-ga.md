---
'@cipherstash/eql': patch
---

**npm prereleases publish under the `latest` dist-tag until 3.0.0 ships.** Until the 3.0.0 final, the alphas are the package's only release line, so `npm install @cipherstash/eql` should resolve to the newest alpha instead of whichever version last happened to hold `latest`. Once 3.0.0 GA is published, prereleases return to their channel dist-tag (`alpha`/`beta`/`rc`) and `latest` stays on finals (`PRE_GA_LATEST` in `packages/eql/scripts/npm-publish.mjs`).
