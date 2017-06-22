## Docker Torque

#### Introduction

This image runs the Torque scheduler and a single worker on a Debian host.

#### Build

`docker build -t torque .`

#### Run

`docker run -h master --privileged -it torque bash`

#### Submit Jobs

`qsub -P batchuser`
