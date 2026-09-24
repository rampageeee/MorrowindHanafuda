# Building

The project can be run from the Defold editor or built headlessly with Bob.
No signing keys, provisioning profiles, certificates, keystores, or other
credentials are included or assumed.

The previously checked command-line toolchain was Defold/Bob 1.13.1 with
OpenJDK 25. If you prefer headless builds, set `BOB` to the Bob JAR and, if
`java` on your PATH is older, set `JAVA` to the OpenJDK 25 executable. Then run
the wrapper for the desired platform:

```sh
BOB=/path/to/bob.jar ./build_tools/build.sh x86_64-linux
BOB=/path/to/bob.jar ./build_tools/build.sh x86_64-win32
BOB=/path/to/bob.jar ./build_tools/build.sh arm64-android
BOB=/path/to/bob.jar ./build_tools/build.sh arm64-ios
BOB=/path/to/bob.jar ./build_tools/build.sh wasm-web
```

On Windows, use `build_tools\\build.bat` from `cmd.exe`:

```bat
set BOB=C:\\path\\to\\bob.jar
build_tools\\build.bat x86_64-win32
```

The platform names above are Bob target names. Common alternatives include
`x86_64-macos`, `arm64-macos`, `arm64-android`, `armv7-android`, and
`wasm-web`. The wrappers write artifacts under `dist/<platform>/` and use the
repository directory as the project root. Pass an optional second argument to
choose another output directory.

Android and iOS package signing is a release step performed outside this
repository. HTML5 output may require a local web server because browsers block
some file:// loading behavior.

## Validation

Before building, confirm that `/game/main.collection` exists and that Bob is
available:

```sh
test -f game.project && test -f game/main.collection
java -version
java -jar "$BOB" --help
```
