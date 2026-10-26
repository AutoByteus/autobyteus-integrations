# AutoByteus Integrations

Integrations connect AutoByteus agents to outside services, such as GitHub, Jira and SSH.

**What an integration is.** A skill with its scripts that lets an agent work with one outside service, and a declaration of the credentials it needs. An integration never contains a secret. The user stores credentials once in the AutoByteus vault, and the platform supplies them only when a command runs, so an agent's shell cannot read them. Where an MCP server is the better route, an integration may also carry its MCP server entry.

**What it is not.** It is not a plugin that extends the AutoByteus application itself. "Integration" means a connection to an outside service; this repository uses the word with that one meaning.

**Status.** New repository. The first content is the integration definition (the folder layout and the credential declaration), which follows the credential design of the AutoByteus Project Task autobyteus-244. No integration is published yet.

**Licence.** Not yet decided. Until a licence file is added, no licence is granted.
