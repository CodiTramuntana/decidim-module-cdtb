## [Unreleased]

## [0.5.2] - 2025-05-23 (patch - Sense por ni flotador)

- Update validate_migrations generator template.

## [0.5.1] - 2025-04-14 (minor - Diferents però igual)

- Add remove ActionLogs of users on remove users task.
- Fix error on add content blocks task.

## [0.5.0] - 2025-04-28 (minor - Unes roques molt gracioses)

- Add task to export the list of admins.
- Upgrade Ruby to 3.1.7.
- Increase minimum Decidim version to v0.28.0.
- Refactor nickname fixer to only fix users with bad nicknames. Do not iterate over all users.

## [0.4.1] - 2025-02-10 (patch -  Afamada i enfadada)

- Fix error in disabling/enabling emails on remove users task

## [0.4.0] - 2025-02-10 (minor - Llefiscós però deliciós)

- Add task to move images to hero content block in participatory spaces
- Improve remove users task disabling and enabling email on moderations

## [0.3.0] - 2024-12-24 (minor - L'artista de la pista)

- Fix YouTube embeds to Decidim v0.28 format in different places. Only YouTube is supported right now.
- Add task to add new content blocks in participatory spaces

## [0.2.1] - 2024-09-25 (patch - Una idea sobre rodes)

- Fix validate_migrations CI which requires Postgres service

## [0.2.0] - 2024-05-10 (Vaig a l'escola, com mola!)

- Upgrade Ruby to 3.0.7
- Upgrade min Decidim version to 0.27

## [0.1.9] - 2024-05-08 (Dona'm gelat o l'hem liat)

- Include a versatile rack attack anti bots and crawlers.
- Add rake task to analyse logs for abusing IPs.

## [0.1.8] - 2024-04-24 (Sapastre i bonastre)

- Fix spam users detector with deleted_at param and hide comments in remover users.

## [0.1.7] - 2024-04-22 (Emocions de colors)

- Fix remove users task and add the reporter user mailer to arguments

## [0.1.6] - 2024-04-11 (Malifetes ben fetes)

- Add remover users task

## [0.1.5] - 2024-02-08 (Pastissos voladors de colors)

- Fix homepage in rubygems.org
- Add organization id and name in spam csv

## [0.1.4] - 2024-01-30 (Peus grans com gegants)

- Add users spam detector task

## [0.1.3] - 2023-06-23 (Tan iguals com especials)

- Validate migrations task

## [0.1.2] - 2023-06-02 (Empastifada amb melmelada)

- Add anonymize rake task

## [0.1.1] - 2023-04-27 (Una mascota trapellota)

- Add tasks to migrate from S3 to :local storage
- Better internal API

## [0.1.0] - 2023-04-18 (Pets i espetecs)

- Initial release
