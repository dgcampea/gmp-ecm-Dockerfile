# GMP-ECM container image

Dockerfile and wrappers for gmp-ecm.

## Building

### Dependencies

- git
- make
- podman

### Instructions

Invoke `make` to build Dockerfile.  
Variables can be overriden with `make VAR=value VAR2=value ...`.  
By default, the image built is tagged as *gmp-ecm:COMMIT_ID* and *gmp-ecm:latest*.  
If`ECM_COMMIT` is specified, the image will not be tagged as *gmp-ecm:latest*.  

For convenience, helper scripts `ecm-wrapper.sh` and `ecm-gwnum-wrapper.sh` 
are installed to `.local/bin`.

#### Makefile variables

##### BUILDER_THREADS
default = ? autodetected amount of cores ?

Make *--jobs* parameter that gets passed to **Dockerfile RUN make ...** directives.  
Setting *-j* at [Building: Instructions](#instructions) has no effect.  
The core detection is done with `grep -c ^processor /proc/cpuinfo`.  
If core autodetection fails, defaults to `1`.

##### REDISTRIBUTABLE
default = yes

If `REDISTRIBUTABLE != yes`, gmp-ecm with GWNUM
will be built alongside regular gmp-ecm.  

##### GMP_VER
default = 6.2.1

gmplib version.  
See: <https://gmplib.org/>

##### GWNUM_VER
default = 303b6

GWNUM version, follows the same versioning as Prime95.  
See: <https://www.mersenne.org/download/>

##### ECM_COMMIT
default = ? latest commit id at HEAD, generated when make is executed ?

Set the image tag and checkout gmp-ecm at the commit specified.  
If the latest commit id at HEAD isn't retrievable, defaults to `HEAD`.  
Can be used to checkout specific commit ids.  
Upstream repo: <https://gitlab.inria.fr/zimmerma/ecm>

## Running

Run `ecm-wrapper.sh`.  
It's intended to be a native `ecm` binary drop-in replacement.

### Running gmp-ecm with GWNUM support
_only available if gmp-ecm image was built with `REDISTRIBUTABLE != yes`_

To use this, run `ecm-gwnum-wrapper.sh`.  
Note: This is achieved by setting the container entrypoint to `/app/bin/gwnum-ecm`.
See `ecm-wrapper.sh` for more details.

### Overriding gmp-ecm image tag used by wrapper script

The default tag used by the wrapper is *latest*.  
This can be controlled using the `ECM_TAG` env variable.  
To use a different tag, run `ECM_TAG=<tag here> ecm-wrapper.sh`.

### Using the image

See `ecm-wrapper.sh` for details on how to use the container image.

## Notes

The image is tuned for the machine used in the build stage which
makes it not suitable for distribution.
