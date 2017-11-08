## Support for D2-only projects

`dlang make`

It will only run `d2conv` if there is no `.D2-ready` file containing the string `ONLY`, in which case the project is considered to be a native D2 project.
