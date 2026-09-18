# ManiNava Docker Homework 01

Docker homework for the DevOps bootcamp (week 3). Everything ran locally on
my Arch machine with docker + docker-compose.

## Folder structure

```
ManiNava_docker_01/
├── 01_docker_images/          # install/version, pull/tag/inspect, layers & history
├── 02_containers_1/           # basics, env vars, port mapping, exec/attach
├── 03_containers_2/           # logs, restart policies, resource limits, health checks
├── 04_volumes_network_1/      # named volume, bind mount, backup/restore
├── 05_volumes_network_2/      # custom network, container comms, isolation
├── 06_docker_compose/         # compose up, networks/volumes, .env vars
├── 07_sample_project/         # nginx + python web app (compose + build)
├── README.md                  # this file
├── overview_qa.txt            # whole-homework Q&A recap
├── final_structure.txt        # find output of the deliverable
└── commands_history.txt       # every docker command I ran
```

## How I ran it

Sections 01 -> 07 in order, one script per sub-task. Each script writes its
report/output files next to itself and prints what it created. The full
run transcript is ManiNava_docker_01_output__maninava.txt at the homework
root.

## Notes

- docker 29.6.0 / compose 5.1.4 on Arch Linux. The PDF assumes a
  debian-ish install; see 01_docker_images/install_docker.sh for the steps
  wich I adapted.
- Two things in the PDF were broken as published: app.py had lost its
  indentation (python crashed, and nginx then failed with "host not found
  in upstream") and `docker ps --format '{{.RestartCount}}'` is gone in
  docker 29.x. I fixed the file and used `docker inspect` instead.
- The committed docker-compose.yml is the .env version (step 6.3 rewrote
  it, and that's the final state).