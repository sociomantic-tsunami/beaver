### The `bintray upload` command learned an option to force a Debian component

For projects that don't comply with SemVer/Neptune, there is a new `beaver
bintray upload` option to override the Debian *component* to which the package
will be uploaded.

For example `beaver bintray upload -C stable *.deb` will upload packages to the
`stable` component instead of the default `release`/`prerelease`. No guessing
will be made at all, if you need to upload to different components based on
different conditions, you need to to the distinction yourself and run the
appropriate `bintray upload -C <comp>` command.
