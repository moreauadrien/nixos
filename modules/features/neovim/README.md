# Java debugging

JDTLS and Microsoft's Java debug bundle come from Nix.
The application's JDK comes from the project's devenv, not the system profile.
`nvim-dap`, `nvim-dap-ui` and `nvim-jdtls` are installed by `vim.pack` on first
startup (network access required). Mason is not used.

After rebuilding NixOS, start Neovim from the project's devenv shell:

```sh
devenv shell
nvim .
```

Enable `languages.java` and choose `languages.java.jdk.package` in the project's
`devenv.nix` (plus `languages.java.maven.enable = true` for Maven).
Neovim reads devenv's `JAVA_HOME` and the JDK's `release` file to register the
matching JDTLS runtime automatically (for example `JavaSE-17` or `JavaSE-21`).
JDTLS itself still runs with its own Nix-packaged Java.
Restart Neovim after changing the project's JDK; do not reuse a Neovim process
started outside the project's environment. Without `JAVA_HOME`, no project JDK
is explicitly registered.

Open a Java source file in a Maven, Gradle or Eclipse project.
Wait for JDTLS to finish importing/building the project, then:

| Key | Action |
| --- | --- |
| `Space b` | Toggle breakpoint |
| `Space B` | Conditional breakpoint |
| `F5` | Discover/select a main class and launch, or continue |
| `F1` / `F2` / `F3` | Step into / over / out |
| `F7` | Toggle variables, watches, call stack and debug console |
| `Space d q` | Terminate the session |

Each project has its own JDTLS workspace under Neovim's cache directory.
Use `:JdtUpdateDebugConfig` to refresh main-class discovery if needed.
Use `:checkhealth vim.lsp`, `:JdtShowLogs` and `:DapShowLog` for troubleshooting.
Projects requiring several JDKs simultaneously need additional entries in
`settings.java.configuration.runtimes` in `lspconfig.lua`; automatic detection
registers only the JDK selected by `JAVA_HOME`.
JUnit debugging is not configured (it requires the separate Java test bundles).

F5 does not offer a remote attach target. If no main class is found, check the
Maven import/build errors and the project's required Java version rather than
trying to connect to port 5005.
