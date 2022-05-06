# syntax=docker/dockerfile:1.4
FROM ubuntu
COPY --link foo.txt /
COPY --link bar.txt /
