# Contributing to the Eve Horizon Starter

Keep the starter minimal, anonymous-cloneable, and safe to generate with
`eve init`. Do not add instance credentials, private repositories, sibling
checkout requirements, or deployment-specific profiles.

The project follows the Eve Horizon
[Code of Conduct](https://github.com/eve-horizon/eve-horizon/blob/main/CODE_OF_CONDUCT.md).
Sign off contributions under the
[Developer Certificate of Origin](https://developercertificate.org/) with
`git commit -s`.

Before opening a pull request, run:

```bash
npm ci --prefix apps/api
npm test --prefix apps/api
docker compose config --quiet
./scripts/validate-starter.sh
```

CI also initializes a clean project with the pinned public Eve CLI and skill
installer. Report vulnerabilities privately as described in
[SECURITY.md](SECURITY.md).
